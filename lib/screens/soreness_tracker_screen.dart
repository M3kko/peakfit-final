// lib/screens/soreness_tracker_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';

import 'preworkout_screen.dart';

class SorenessTrackerScreen extends StatefulWidget {
  final String workoutType;
  final int duration;

  const SorenessTrackerScreen({
    Key? key,
    required this.workoutType,
    required this.duration,
  }) : super(key: key);

  @override
  State<SorenessTrackerScreen> createState() => _SorenessTrackerScreenState();
}

class _SorenessTrackerScreenState extends State<SorenessTrackerScreen>
    with TickerProviderStateMixin {
  // Animations
  late final AnimationController _fadeCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _slideUp;
  late final Animation<double> _pulse;

  // Raw svg viewBox (from your file)
  static const double _vbW = 156.0;
  static const double _vbH = 236.0;

  // Parsed muscle paths (id -> Path in viewBox coords)
  Map<String, Path> _paths = {};
  // Selected ids
  final Set<String> _selected = {};

  // Muscle display names
  static const Map<String, String> _names = {
    'neck': 'Neck',
    'upper-trapezius': 'Upper Traps',
    'traps-middle': 'Middle Traps',
    'lower-trapezius': 'Lower Traps',
    'right-lats': 'Right Lats',
    'left-lats': 'Left Lats',
    'right-posterior-deltoid': 'Right Rear Delt',
    'left-posterior-deltoid': 'Left Rear Delt',
    'right-lateral-deltoid': 'Right Side Delt',
    'left-lateral-deltoid': 'Left Side Delt',
    'right-long-head-triceps': 'Right Triceps (Long)',
    'left-long-head-triceps': 'Left Triceps (Long)',
    'right-lateral-head-triceps': 'Right Triceps (Lateral)',
    'left-medial-head-triceps': 'Left Triceps (Medial)',
    'right-wrist-flexors': 'Right Wrist Flexors',
    'left-wrist-flexors': 'Left Wrist Flexors',
    'right-wrist-extensors': 'Right Wrist Extensors',
    'left-wrist-extensors': 'Left Wrist Extensors',
    'right-hand': 'Right Hand',
    'left-hand': 'Left Hand',
    'right-gluteus-medius': 'Right Glute Medius',
    'left-gluteus-medius': 'Left Glute Medius',
    'right-gluteus-maximus': 'Right Glute Max',
    'left-gluteus-maximus': 'Left Glute Max',
    'left-inner-thigh': 'Left Inner Thigh',
    'right-inner-thigh': 'Right Inner Thigh',
    'right-lateral-hamstring': 'Right Lateral Hamstring',
    'left-lateral-hamstring': 'Left Lateral Hamstring',
    'right-medial-hamstring': 'Right Medial Hamstring',
    'left-medial-hamstring': 'Left Medial Hamstring',
    'left-soleus': 'Left Soleus',
    'right-soleus': 'Right Soleus',
    'left-gastrocnemius': 'Left Gastrocnemius',
    'right-gastrocnemius': 'Right Gastrocnemius',
    'left-foot': 'Left Foot',
    'right-foot': 'Right Foot',
    'lower-back': 'Lower Back',
  };

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 24, end: 0).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fadeCtrl.forward();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    final raw = await rootBundle.loadString('assets/svg/backmuscle-final.svg');
    final doc = XmlDocument.parse(raw);

    /// Your SVG has a group transform: translate(-27.789474,-29.526316)
    /// We need to shift paths back so the geometry lines up with what we paint.
    const dx = 27.789474;
    const dy = 29.526316;

    final map = <String, Path>{};
    for (final p in doc.findAllElements('path')) {
      final id = p.getAttribute('id');
      final d = p.getAttribute('d');
      if (id == null || d == null) continue;
      Path path = parseSvgPathData(d).shift(const Offset(dx, dy));
      map[id] = path;
    }

    if (mounted) setState(() => _paths = map);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Transform.translate(
                offset: Offset(0, _slideUp.value),
                child: Column(
                  children: [
                    _header(context),
                    Expanded(child: _body()),
                  ],
                ),
              ),
            ),
          ),
          _bottomButton(context),
        ],
      ),
    );
  }

  Widget _background() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A0A0A), Color(0xFF0F0F0F), Color(0xFF050505)],
        stops: [0, 0.5, 1],
      ),
    ),
  );

  Widget _header(BuildContext ctx) => Padding(
    padding: const EdgeInsets.all(24),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(ctx),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const Spacer(),
        Text(
          'SORENESS CHECK',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 2,
            fontWeight: FontWeight.w300,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    ),
  );

  Widget _body() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'How are you feeling?',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w200),
        ),
        const SizedBox(height: 12),
        Text('Tap muscles that feel sore', style: TextStyle(color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 40),
        _diagram(),
        const SizedBox(height: 40),
        _legend(),
        const SizedBox(height: 100),
      ],
    ),
  );

  Widget _diagram() {
    return AspectRatio(
      aspectRatio: _vbW / _vbH,
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (_, c) {
            final sx = c.maxWidth / _vbW;
            final sy = c.maxHeight / _vbH;

            return Stack(
              children: [
                // Base SVG
                SvgPicture.asset(
                  'assets/svg/backmuscle-final.svg',
                  fit: BoxFit.contain,
                  width: c.maxWidth,
                  height: c.maxHeight,
                ),
                // Highlights
                CustomPaint(
                  size: Size(c.maxWidth, c.maxHeight),
                  painter: _HighlightPainter(
                    selected: _selected,
                    paths: _paths,
                    sx: sx,
                    sy: sy,
                  ),
                ),
                // Hit detection
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      if (_paths.isEmpty) return;
                      final local = d.localPosition;
                      final xSvg = local.dx / sx;
                      final ySvg = local.dy / sy;
                      for (final e in _paths.entries) {
                        if (e.value.contains(Offset(xSvg, ySvg))) {
                          _toggle(e.key);
                          break;
                        }
                      }
                    },
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _legend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SELECTED MUSCLES',
              style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 1.5, fontSize: 12)),
          const SizedBox(height: 16),
          if (_selected.isEmpty)
            Center(
              child: Text('No muscles selected',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selected.map((id) {
                final name = _names[id] ?? id;
                return Chip(
                  label: Text(name.toUpperCase(), style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                  backgroundColor: Colors.red.withOpacity(0.2),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _bottomButton(BuildContext ctx) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFF0A0A0A),
                const Color(0xFF0A0A0A).withOpacity(0.9),
                const Color(0xFF0A0A0A).withOpacity(0),
              ],
            ),
          ),
          child: ScaleTransition(
            scale: _pulse,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                Navigator.push(
                  ctx,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => PreWorkoutScreen(
                      workoutType: widget.workoutType,
                      duration: widget.duration,
                    ),
                    transitionsBuilder: (_, anim, __, child) {
                      final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
                          .chain(CurveTween(curve: Curves.easeOutExpo));
                      return SlideTransition(position: anim.drive(tween), child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE0E0E0)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('CONTINUE',
                          style: TextStyle(
                            color: Colors.black,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          )),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final Set<String> selected;
  final Map<String, Path> paths;
  final double sx, sy;

  _HighlightPainter({
    required this.selected,
    required this.paths,
    required this.sx,
    required this.sy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.red.withOpacity(0.28);
    canvas.save();
    canvas.scale(sx, sy);
    for (final id in selected) {
      final p = paths[id];
      if (p != null) canvas.drawPath(p, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter old) {
    return !setEquals(old.selected, selected) ||
        !mapEquals(old.paths, paths) ||
        old.sx != sx ||
        old.sy != sy;
  }
}
