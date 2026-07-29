import 'dart:math';
import 'package:flutter/material.dart';
import 'jcbs_page.dart';

// ─────────────────────────────────────────────────
// Radar / Map View for nearby vehicles
// ─────────────────────────────────────────────────
class JcbsMapView extends StatefulWidget {
  final List<JcbsListing> listings;
  final double userLat;
  final double userLng;
  final void Function(String phone) onCallTap;
  final void Function(JcbsListing item) onDetailsTap;

  const JcbsMapView({
    Key? key,
    required this.listings,
    required this.userLat,
    required this.userLng,
    required this.onCallTap,
    required this.onDetailsTap,
  }) : super(key: key);

  @override
  State<JcbsMapView> createState() => _JcbsMapViewState();
}

class _JcbsMapViewState extends State<JcbsMapView>
    with TickerProviderStateMixin {
  JcbsListing? _selected;
  late AnimationController _pulseCtrl;
  late AnimationController _sweepCtrl;
  late Animation<double> _pulseAnim;
  // Pan offset for dragging the radar
  Offset _panOffset = Offset.zero;
  Offset _startPan = Offset.zero;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _sweepCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _sweepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildRadar()),
        if (_selected != null) _buildSelectedCard(_selected!),
      ],
    );
  }

  Widget _buildRadar() {
    return GestureDetector(
      onScaleStart: (d) {
        _startPan = d.focalPoint - _panOffset;
      },
      onScaleUpdate: (d) {
        setState(() {
          _scale = d.scale.clamp(0.5, 3.0);
          _panOffset = d.focalPoint - _startPan;
        });
      },
      child: Container(
        color: const Color(0xFF0A1628),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final center =
                Offset(constraints.maxWidth / 2, constraints.maxHeight / 2) +
                    _panOffset;
            return AnimatedBuilder(
              animation: Listenable.merge([_pulseCtrl, _sweepCtrl]),
              builder: (_, __) {
                return CustomPaint(
                  painter: _RadarPainter(
                    center: center,
                    scale: _scale,
                    pulseValue: _pulseAnim.value,
                    sweepAngle: _sweepCtrl.value * 2 * pi,
                    listings: widget.listings,
                    userLat: widget.userLat,
                    userLng: widget.userLng,
                    selected: _selected,
                  ),
                  child: Stack(
                    children: [
                      // Vehicle tap targets
                      ...widget.listings.map((v) {
                        final pos = _latlngToOffset(
                            v.latitude, v.longitude, center, _scale);
                        return Positioned(
                          left: pos.dx - 20,
                          top: pos.dy - 20,
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _selected = _selected == v ? null : v),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: _JcbsMapMarker(
                                item: v,
                                isSelected: _selected == v,
                              ),
                            ),
                          ),
                        );
                      }),
                      // Center - user dot
                      Positioned(
                        left: center.dx - 12,
                        top: center.dy - 12,
                        child: _UserDot(pulse: _pulseAnim.value),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Offset _latlngToOffset(double lat, double lng, Offset center, double scale) {
    // Convert lat/lng delta to pixels
    // 0.001 degree ≈ 111m
    final dLat = lat - widget.userLat;
    final dLng = lng - widget.userLng;
    const pixelsPerDegree = 2800.0; // tuned for Calicut city scale
    final dx = dLng * pixelsPerDegree * scale;
    final dy = -dLat * pixelsPerDegree * scale;
    return center + Offset(dx, dy);
  }

  Widget _buildSelectedCard(JcbsListing item) {
    final dist = item.distanceFrom(widget.userLat, widget.userLng);
    final eta = item.etaMinutes(widget.userLat, widget.userLng);
    final distStr = dist < 1
        ? '${(dist * 1000).round()} m away'
        : '${dist.toStringAsFixed(1)} km away';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: item.isAgency
                    ? const Icon(Icons.domain_outlined,
                        color: Color(0xFF0F2E5A), size: 26)
                    : Center(
                        child: Image.asset('assets/icons/jcb.png',
                            width: 26, height: 26, color: Colors.blue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Color(0xFF0F2E5A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (item.isVerified)
                          const Icon(Icons.verified_user_rounded,
                              color: Color(0xFF4F46E5), size: 14),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.vehicleDetails,
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    distStr,
                    style: const TextStyle(
                        color: Color(0xFF0F2E5A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  Text(
                    '~$eta min away',
                    style:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onCallTap(item.phone),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2E5A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_in_talk,
                            color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text("Call Now",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => widget.onDetailsTap(item),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF0F2E5A), size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Radar CustomPainter
// ─────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final Offset center;
  final double scale;
  final double pulseValue;
  final double sweepAngle;
  final List<JcbsListing> listings;
  final double userLat;
  final double userLng;
  final JcbsListing? selected;

  _RadarPainter({
    required this.center,
    required this.scale,
    required this.pulseValue,
    required this.sweepAngle,
    required this.listings,
    required this.userLat,
    required this.userLng,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid rings
    final ringPaint = Paint()
      ..color = const Color(0xFF1A3A5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, i * 70.0 * scale, ringPaint);
    }

    // Crosshair lines
    final crossPaint = Paint()
      ..color = const Color(0xFF1A3A5C)
      ..strokeWidth = 0.8;
    canvas.drawLine(
        Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);
    canvas.drawLine(
        Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);

    // Radar sweep gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle,
        endAngle: sweepAngle + pi * 0.5,
        colors: [
          Colors.transparent,
          const Color(0xFFFFB800).withOpacity(0.0),
          const Color(0xFFFFB800).withOpacity(0.12),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: 350 * scale),
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 350 * scale, sweepPaint);

    // Sweep line
    final linePaint = Paint()
      ..color = const Color(0xFFFFB800).withOpacity(0.7)
      ..strokeWidth = 1.5;
    final lineEnd = Offset(
      center.dx + cos(sweepAngle) * 350 * scale,
      center.dy + sin(sweepAngle) * 350 * scale,
    );
    canvas.drawLine(center, lineEnd, linePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.sweepAngle != sweepAngle ||
      old.pulseValue != pulseValue ||
      old.scale != scale ||
      old.center != center ||
      old.selected != selected;
}

// ─────────────────────────────────────────────────
// Vehicle marker widget
// ─────────────────────────────────────────────────
class _JcbsMapMarker extends StatelessWidget {
  final JcbsListing item;
  final bool isSelected;

  const _JcbsMapMarker({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFB800) : const Color(0xFF1A3A5C),
        borderRadius: BorderRadius.circular(isSelected ? 14 : 10),
        border: Border.all(
          color: isSelected ? Colors.white : const Color(0xFF3B5998),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isSelected ? const Color(0xFFFFB800) : const Color(0xFF0F2E5A))
                    .withOpacity(0.5),
            blurRadius: isSelected ? 12 : 4,
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: item.isAgency
          ? Icon(Icons.domain,
              color: isSelected
                  ? const Color(0xFF0F2E5A)
                  : const Color(0xFFFFB800),
              size: 18)
          : Image.asset('assets/icons/jcb.png',
              width: 18,
              height: 18,
              color: isSelected
                  ? const Color(0xFF0F2E5A)
                  : const Color(0xFFFFB800)),
    );
  }
}

// ─────────────────────────────────────────────────
// User location dot with pulsing ring
// ─────────────────────────────────────────────────
class _UserDot extends StatelessWidget {
  final double pulse;
  const _UserDot({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          Container(
            width: 24 * pulse,
            height: 24 * pulse,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
          ),
          // Core dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.blue, blurRadius: 8, spreadRadius: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
