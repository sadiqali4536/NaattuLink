import 'dart:async';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/model/services/google_places_service.dart';
import 'package:naattulink/MVVM/model/services/translation_service.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:get/get.dart';

class LocationAutocompleteField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final Map<String, dynamic>? initialLocationData;
  final Function(Map<String, dynamic>) onLocationSelected;
  final VoidCallback? onCleared;

  const LocationAutocompleteField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.onLocationSelected,
    this.initialLocationData,
    this.onCleared,
  }) : super(key: key);

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isTranslating = false;
  bool _showSuggestions = false;
  
  Map<String, dynamic>? _selectedLocation;
  
  // To track translation review
  Map<String, String>? _pendingTranslations;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocationData != null) {
      _selectedLocation = widget.initialLocationData;
      widget.controller.text = _selectedLocation?['english'] ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Clear selected if user starts typing something else
    if (_selectedLocation != null) {
      _selectedLocation = null;
      _pendingTranslations = null;
      if (widget.onCleared != null) widget.onCleared!();
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestions = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await GooglePlacesService.getSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  Future<void> _selectPlace(Map<String, dynamic>? suggestion, String manualText) async {
    setState(() {
      _showSuggestions = false;
      _isTranslating = true;
    });

    FocusScope.of(context).unfocus();

    Map<String, dynamic> locationData = {};

    if (suggestion != null) {
      // Google Place selected
      widget.controller.text = suggestion['mainText'];
      final details = await GooglePlacesService.getPlaceDetails(suggestion['placeId']);
      
      locationData = {
        'english': suggestion['mainText'],
        'placeId': suggestion['placeId'],
        'formattedAddress': details?['formattedAddress'],
        'latitude': details?['latitude'],
        'longitude': details?['longitude'],
        'source': 'google_places',
        'verified': true,
      };
    } else {
      // Manual entry
      widget.controller.text = manualText;
      locationData = {
        'english': manualText,
        'placeId': null,
        'formattedAddress': null,
        'latitude': null,
        'longitude': null,
        'source': 'manual',
        'verified': false,
      };
    }

    // Now Translate
    try {
      final translations = await TranslationService.translateLocation(locationData['english']);
      locationData['malayalam'] = translations['malayalam'];
      locationData['hindi'] = translations['hindi'];
      
      setState(() {
        _selectedLocation = locationData;
        _pendingTranslations = translations;
      });

      _showTranslationReview(locationData);
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      CherryToast.error(title: const Text('Translation failed. Please try again.')).show(context);
    }
  }

  void _showTranslationReview(Map<String, dynamic> locationData) {
    setState(() {
      _isTranslating = false;
    });
    
    // Auto confirm for now, but show a toast.
    widget.onLocationSelected(locationData);
    
    // Optional: show a small dialog or inline UI for review.
    // Given the constraints to not clutter the UI, we can just save it.
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              TextField(
                controller: widget.controller,
                onChanged: _onSearchChanged,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(widget.icon, color: Colors.grey.shade500, size: 20),
                  suffixIcon: _isTranslating
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : (_selectedLocation != null 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              
              if (_showSuggestions && widget.controller.text.length >= 2)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: _isLoadingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _suggestions.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _suggestions.length) {
                              // Fallback manual entry item
                              return ListTile(
                                leading: const Icon(Icons.edit_location_alt, color: Colors.grey),
                                title: const Text('Use typed location', style: TextStyle(color: Colors.blue)),
                                onTap: () => _selectPlace(null, widget.controller.text.trim()),
                              );
                            }

                            final s = _suggestions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.grey),
                              title: Text(s['mainText']),
                              subtitle: s['secondaryText'].isNotEmpty ? Text(s['secondaryText'], maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                              onTap: () => _selectPlace(s, ''),
                            );
                          },
                        ),
                ),
            ],
          ),
        ),
        
        if (_selectedLocation != null && _pendingTranslations != null)
           Padding(
             padding: const EdgeInsets.only(top: 8.0, left: 4.0),
             child: Text(
               'ML: ${_pendingTranslations!['malayalam']} | HI: ${_pendingTranslations!['hindi']}',
               style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
             ),
           ),
      ],
    );
  }
}
