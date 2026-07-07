import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swiftclean_project/MVVM/utils/Config/Toast.dart';

/// A self-contained widget that lets a worker set & save their business location.
/// Drop this anywhere inside the Worker Dashboard / Home page.
class WorkerLocationWidget extends StatefulWidget {
  const WorkerLocationWidget({super.key});

  @override
  State<WorkerLocationWidget> createState() => _WorkerLocationWidgetState();
}

class _WorkerLocationWidgetState extends State<WorkerLocationWidget> {
  // ── State ────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDetecting = false;

  // Saved values from Firestore
  double? _savedLat;
  double? _savedLng;
  String _savedAddress = '';
  String _savedMapsUrl = '';

  // Edit state
  final _linkController = TextEditingController();
  bool _editMode = false;

  static const _primaryBlue = Color(0xFF0F2E5A);
  static const _accentGold = Color(0xFFFFB800);
  static const _textGrey = Color(0xFF64748B);

  // ── Lifecycle ────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  // ── Firestore ────────────────────────────────────────────────────
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _loadSavedLocation() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(_uid)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _savedLat = (data['businessLat'] as num?)?.toDouble();
          _savedLng = (data['businessLng'] as num?)?.toDouble();
          _savedAddress = data['businessAddress'] as String? ?? '';
          _savedMapsUrl = data['businessMapsUrl'] as String? ?? '';
        });
      }
    } catch (e) {
      debugPrint('WorkerLocationWidget load error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToFirestore({
    required double lat,
    required double lng,
    required String address,
    required String mapsUrl,
  }) async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('workers').doc(_uid).update({
        'businessLat': lat,
        'businessLng': lng,
        'businessAddress': address,
        'businessMapsUrl': mapsUrl,
      });
      setState(() {
        _savedLat = lat;
        _savedLng = lng;
        _savedAddress = address;
        _savedMapsUrl = mapsUrl;
        _editMode = false;
      });
      toastSuccess('Business location saved!');
    } catch (e) {
      toastError('Could not save location: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── GPS Detection ─────────────────────────────────────────────────
  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetecting = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        toastError('Location permission is permanently denied. Please enable it in Settings.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ));

      final lat = pos.latitude;
      final lng = pos.longitude;
      final mapsUrl =
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

      await _saveToFirestore(
        lat: lat,
        lng: lng,
        address: '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
        mapsUrl: mapsUrl,
      );
    } catch (e) {
      toastError('Could not detect location: $e');
    } finally {
      setState(() => _isDetecting = false);
    }
  }

  // ── Paste Link Parser ─────────────────────────────────────────────
  /// Extracts lat/lng from common Google Maps share link formats:
  ///   https://maps.app.goo.gl/...  (redirects, fallback)
  ///   https://www.google.com/maps/place/.../data=...!4d75.780411!3d11.258753
  ///   https://www.google.com/maps?q=11.258753,75.780411
  ///   https://maps.google.com/?ll=11.258753,75.780411
  static final _latLngPatterns = [
    // ?q=lat,lng  or  ll=lat,lng
    RegExp(r'[?&](?:q|ll)=([-\d.]+),([-\d.]+)'),
    // /maps/place/.../@ lat,lng
    RegExp(r'@([-\d.]+),([-\d.]+)'),
    // !3d<lat>!4d<lng>  (embedded in data param)
    RegExp(r'!3d([-\d.]+).*?!4d([-\d.]+)'),
    // destination=lat,lng
    RegExp(r'destination=([-\d.]+),([-\d.]+)'),
  ];

  Map<String, double>? _parseMapsLink(String url) {
    for (final re in _latLngPatterns) {
      final m = re.firstMatch(url);
      if (m != null) {
        final lat = double.tryParse(m.group(1)!);
        final lng = double.tryParse(m.group(2)!);
        if (lat != null && lng != null) return {'lat': lat, 'lng': lng};
      }
    }
    return null;
  }

  Future<void> _savePastedLink() async {
    final raw = _linkController.text.trim();
    if (raw.isEmpty) {
      toastError('Please paste a Google Maps link first.');
      return;
    }

    final parsed = _parseMapsLink(raw);
    if (parsed == null) {
      toastError('Could not read coordinates from this link. Try a link with visible lat/lng (e.g., from Google Maps "Share > Copy Link").');
      return;
    }

    final lat = parsed['lat']!;
    final lng = parsed['lng']!;
    final mapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

    await _saveToFirestore(
      lat: lat,
      lng: lng,
      address: '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
      mapsUrl: mapsUrl,
    );
  }

  // ── Open in Maps (preview own location) ──────────────────────────
  Future<void> _previewLocation() async {
    if (_savedMapsUrl.isEmpty) return;
    final uri = Uri.parse(_savedMapsUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      toastError('Could not open Google Maps.');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: _primaryBlue)),
      );
    }

    final hasLocation = _savedLat != null && _savedLng != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on, color: _primaryBlue, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Location',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Users will see this on your profile',
                      style: TextStyle(color: _textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (hasLocation && !_editMode)
                GestureDetector(
                  onTap: () => setState(() => _editMode = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 13, color: _textGrey),
                        SizedBox(width: 4),
                        Text('Edit', style: TextStyle(color: _textGrey, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Saved Location Preview ───────────────────────
          if (hasLocation && !_editMode) ...[
            GestureDetector(
              onTap: _previewLocation,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place, color: Color(0xFF059669), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _savedAddress.isNotEmpty
                                ? _savedAddress
                                : '${_savedLat!.toStringAsFixed(5)}, ${_savedLng!.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tap to preview in Google Maps',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new, color: Color(0xFF059669), size: 16),
                  ],
                ),
              ),
            ),
          ],

          // ── Edit / Set Location Form ─────────────────────
          if (!hasLocation || _editMode) ...[
            // Option 1: Paste Google Maps link
            const Text(
              'Option 1 — Paste a Google Maps link',
              style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _linkController,
                      style: const TextStyle(fontSize: 13, color: _primaryBlue),
                      decoration: const InputDecoration(
                        hintText: 'Paste Google Maps sharing link here...',
                        hintStyle: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        prefixIcon: Icon(Icons.link_rounded, color: _textGrey, size: 18),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _linkController.text = data!.text!;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: const Text(
                        'Paste',
                        style: TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // How to get a link hint
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFB45309), size: 14),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Open Google Maps → Find your location → Tap Share → Copy Link → Paste above.',
                      style: TextStyle(color: Color(0xFFB45309), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePastedLink,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_alt_rounded, size: 16),
                label: Text(_isSaving ? 'Saving...' : 'Save Link Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(height: 16),

            // Option 2: Use GPS
            const Text(
              'Option 2 — Use my current GPS location',
              style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDetecting ? null : _detectCurrentLocation,
                icon: _isDetecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue),
                      )
                    : const Icon(Icons.my_location_rounded, size: 16, color: _primaryBlue),
                label: Text(
                  _isDetecting ? 'Detecting...' : 'Use My Current Location',
                  style: const TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGold,
                  foregroundColor: _primaryBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            if (_editMode) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => setState(() {
                    _editMode = false;
                    _linkController.clear();
                  }),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: _textGrey, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
