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
  late final AnimationController _switchCtrl;
  late final AnimationController _selectedPulseCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _slideUp;
  late final Animation<double> _pulse;
  late final Animation<double> _switchFade;
  late final Animation<double> _selectedPulse;

  // View state
  bool _showingFront = true;
  bool _isLoading = true;
  String _loadError = '';

  // Raw SVG viewBox dimensions
  static const double _frontVbW = 210.0;
  static const double _frontVbH = 297.0;
  static const double _backVbW = 210.0;
  static const double _backVbH = 297.0;

  // Parsed paths for both views
  Map<String, Path> _frontPaths = {};
  Map<String, Path> _backPaths = {};
  final Set<String> _selectedFront = {};
  final Set<String> _selectedBack = {};

  // Get current selection based on view
  Set<String> get _currentSelection => _showingFront ? _selectedFront : _selectedBack;
  Map<String, Path> get _currentPaths => _showingFront ? _frontPaths : _backPaths;

  // Muscle display names for front
  static const Map<String, String> _frontNames = {
    'neck': 'Neck',
    'upper-trapezius-left': 'Left Upper Traps',
    'upper-trapezius-right': 'Right Upper Traps',
    'upper-pectoralis-right': 'Right Upper Chest',
    'upper-pectoralis-left': 'Left Upper Chest',
    'anterior-deltoid-right': 'Right Front Delt',
    'anterior-deltoid-left': 'Left Front Delt',
    'lateral-deltoid-right': 'Right Side Delt',
    'lateral-deltoid-left': 'Left Side Delt',
    'mid-lower-pectoralis-right': 'Right Lower Chest',
    'mid-lower-pectoralis-left': 'Left Lower Chest',
    'obliques-left': 'Left Obliques',
    'obliques-right': 'Right Obliques',
    'short-head-bicep-left': 'Left Bicep (Short)',
    'long-head-bicep-left': 'Left Bicep (Long)',
    'short-head-bicep-right': 'Right Bicep (Short)',
    'long-head-bicep-right': 'Right Bicep (Long)',
    'wrist-extensors-left': 'Left Wrist Extensors',
    'wrist-flexors-left': 'Left Wrist Flexors',
    'wrist-left': 'Left Wrist',
    'wrist-extensors-right': 'Right Wrist Extensors',
    'wrist-flexors-right': 'Right Wrist Flexors',
    'wrist-right': 'Right Wrist',
    'groin': 'Groin',
    'lower-abdominals': 'Lower Abs',
    'upper-abdominals': 'Upper Abs',
    'outer-quadricep-right': 'Right Outer Quad',
    'outer-quadricep-left': 'Left Outer Quad',
    'rectus-femoris-right': 'Right Rectus Femoris',
    'rectus-femoris-left': 'Left Rectus Femoris',
    'inner-quadricep-right': 'Right Inner Quad',
    'inner-quadricep-left': 'Left Inner Quad',
    'inner-thigh-right': 'Right Inner Thigh',
    'inner-thigh-left': 'Left Inner Thigh',
    'tibialis-right': 'Right Tibialis',
    'tibialis-left': 'Left Tibialis',
    'gastrocnemius-right': 'Right Calf',
    'gastrocnemius-left': 'Left Calf',
    'soleus-right': 'Right Soleus',
    'soleus-left': 'Left Soleus',
    'foot-right': 'Right Foot',
    'foot-left': 'Left Foot',
  };

  // Muscle display names for back
  static const Map<String, String> _backNames = {
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
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _switchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _selectedPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 30, end: 0)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 0.96, end: 1.04)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _switchFade = CurvedAnimation(parent: _switchCtrl, curve: Curves.easeInOut);
    _selectedPulse = Tween<double>(begin: 0.3, end: 0.5)
        .animate(CurvedAnimation(parent: _selectedPulseCtrl, curve: Curves.easeInOut));

    _fadeCtrl.forward();
    _switchCtrl.value = 1.0;
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    try {
      setState(() {
        _isLoading = true;
        _loadError = '';
      });

      // Load front muscles
      final frontRaw = await rootBundle.loadString('assets/svg/final-front-muscles.svg');
      final frontDoc = XmlDocument.parse(frontRaw);

      final frontMap = <String, Path>{};
      for (final e in frontDoc.findAllElements('path')) {
        final id = e.getAttribute('id');
        final d = e.getAttribute('d');
        if (id == null || d == null) continue;

        // Skip non-muscle paths
        if (id.startsWith('path') && RegExp(r'^\d+$').hasMatch(id.substring(4))) continue;

        try {
          final p = parseSvgPathData(d);
          frontMap[id] = p;
        } catch (e) {
          print('Error parsing front path $id: $e');
        }
      }

      // Load back muscles
      final backRaw = await rootBundle.loadString('assets/svg/backmuscle-final.svg');
      final backDoc = XmlDocument.parse(backRaw);

      final backMap = <String, Path>{};
      for (final e in backDoc.findAllElements('path')) {
        final id = e.getAttribute('id');
        final d = e.getAttribute('d');
        if (id == null || d == null) continue;

        // Skip non-muscle paths
        if (id.startsWith('path') && RegExp(r'^\d+$').hasMatch(id.substring(4))) continue;

        try {
          final p = parseSvgPathData(d);
          backMap[id] = p;
        } catch (e) {
          print('Error parsing back path $id: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _frontPaths = frontMap;
        _backPaths = backMap;
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading paths: $e');
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _switchCtrl.dispose();
    _selectedPulseCtrl.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_showingFront) {
        if (_selectedFront.contains(id)) {
          _selectedFront.remove(id);
        } else {
          _selectedFront.add(id);
        }
      } else {
        if (_selectedBack.contains(id)) {
          _selectedBack.remove(id);
        } else {
          _selectedBack.add(id);
        }
      }
    });
  }

  void _switchView() {
    HapticFeedback.mediumImpact();
    _switchCtrl.reverse().then((_) {
      setState(() {
        _showingFront = !_showingFront;
      });
      _switchCtrl.forward();
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
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          const Color(0xFF1A1A1A),
          const Color(0xFF0A0A0A),
        ],
      ),
    ),
    child: CustomPaint(
      painter: _GridPainter(opacity: 0.03),
    ),
  );

  Widget _header(BuildContext ctx) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
        ),
        const Spacer(),
        Column(
          children: [
            Text(
              'SORENESS CHECK',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 3,
                fontWeight: FontWeight.w200,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 100,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFD4AF37).withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    ),
  );

  Widget _body() => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        const SizedBox(height: 16),
        _titleSection(),
        const SizedBox(height: 32),
        _viewToggle(),
        const SizedBox(height: 24),
        if (_isLoading)
          SizedBox(
            height: 400,
            child: Center(
              child: CircularProgressIndicator(
                color: const Color(0xFFD4AF37).withOpacity(0.8),
                strokeWidth: 2,
              ),
            ),
          )
        else if (_loadError.isNotEmpty)
          Container(
            height: 400,
            alignment: Alignment.center,
            child: Text('Error: $_loadError', style: const TextStyle(color: Colors.red)),
          )
        else
          FadeTransition(
            opacity: _switchFade,
            child: _diagram(),
          ),
        const SizedBox(height: 32),
        _legend(),
        const SizedBox(height: 120),
      ],
    ),
  );

  Widget _titleSection() => Column(
    children: [
      ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        child: const Text(
          'How are you feeling?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w200,
            letterSpacing: -0.5,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Tap muscles that feel sore',
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );

  Widget _viewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewToggleButton('FRONT', _showingFront, () => _showingFront ? null : _switchView()),
          const SizedBox(width: 8),
          _viewToggleButton('BACK', !_showingFront, () => !_showingFront ? null : _switchView()),
        ],
      ),
    );
  }

  Widget _viewToggleButton(String label, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFFD4AF37).withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.4),
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _diagram() {
    final svgPath = _showingFront
        ? 'assets/svg/final-front-muscles.svg'
        : 'assets/svg/backmuscle-final.svg';

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Make the diagram larger - use 60% of screen height
    final maxHeight = screenHeight * 0.6;
    final maxWidth = screenWidth - 40; // Account for padding

    // Calculate scale to fit within constraints while maintaining aspect ratio
    final aspectRatio = _frontVbW / _frontVbH;
    double svgHeight = maxHeight;
    double svgWidth = svgHeight * aspectRatio;

    // If width exceeds max, scale down
    if (svgWidth > maxWidth) {
      svgWidth = maxWidth;
      svgHeight = svgWidth / aspectRatio;
    }

    final scale = svgWidth / _frontVbW;

    return Container(
      height: svgHeight + 20, // Add some padding
      width: screenWidth,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // REMOVED: Background glow AnimatedBuilder section

          // SVG Display
          SizedBox(
            width: svgWidth,
            height: svgHeight,
            child: SvgPicture.asset(
              svgPath,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),

          // Custom Paint overlay for highlights
          SizedBox(
            width: svgWidth,
            height: svgHeight,
            child: AnimatedBuilder(
              animation: _selectedPulse,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(svgWidth, svgHeight),
                  painter: _HighlightPainter(
                    selected: _currentSelection,
                    paths: _currentPaths,
                    scale: scale,
                    pulseValue: _selectedPulse.value,
                  ),
                );
              },
            ),
          ),

          // Gesture Detector
          SizedBox(
            width: svgWidth,
            height: svgHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                if (_currentPaths.isEmpty) return;

                final lp = d.localPosition;
                final x = lp.dx / scale;
                final y = lp.dy / scale;

                for (final e in _currentPaths.entries) {
                  if (e.value.contains(Offset(x, y))) {
                    _toggle(e.key);
                    break;
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend() {
    final currentNames = _showingFront ? _frontNames : _backNames;
    final currentSelection = _showingFront ? _selectedFront : _selectedBack;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.03),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.white.withOpacity(0.5), size: 16),
                    const SizedBox(width: 8),
                    Text('SELECTED MUSCLES',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 1.5, fontSize: 11)),
                  ],
                ),
              ),
              const Spacer(),
              if (currentSelection.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (_showingFront) {
                        _selectedFront.clear();
                      } else {
                        _selectedBack.clear();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text('CLEAR ALL',
                        style: TextStyle(color: Colors.red.shade300, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (currentSelection.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.white.withOpacity(0.2), size: 32),
                  const SizedBox(height: 8),
                  Text('No muscles selected',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentSelection.map((id) {
                final name = currentNames[id] ?? id;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Chip(
                        label: Text(name.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                        backgroundColor: Colors.red.withOpacity(0.2),
                        side: BorderSide(color: Colors.red.withOpacity(0.4)),
                        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                        onDeleted: () => _toggle(id),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _bottomButton(BuildContext ctx) {
    final hasSelection = _selectedFront.isNotEmpty || _selectedBack.isNotEmpty;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
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
              final allSoreMuscles = {..._selectedFront, ..._selectedBack};

              Navigator.push(
                ctx,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => PreWorkoutScreen(
                    workoutType: widget.workoutType,
                    duration: widget.duration,
                    soreMuscles: allSoreMuscles.toList(),
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
                gradient: LinearGradient(
                  colors: hasSelection
                      ? [const Color(0xFFD4AF37), const Color(0xFFB8941F)]
                      : [Colors.white, const Color(0xFFE0E0E0)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: hasSelection
                        ? const Color(0xFFD4AF37).withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasSelection ? 'CONTINUE WITH ${_selectedFront.length + _selectedBack.length} AREAS' : 'CONTINUE',
                      style: TextStyle(
                        color: hasSelection ? Colors.white : Colors.black,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: hasSelection ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ],
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
  final double scale;
  final double pulseValue;

  _HighlightPainter({
    required this.selected,
    required this.paths,
    required this.scale,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selected.isEmpty) return;

    final paint = Paint()
      ..color = Colors.red.withOpacity(pulseValue)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale;

    final glowPaint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.save();
    canvas.scale(scale, scale);

    for (final id in selected) {
      final p = paths[id];
      if (p != null) {
        // Draw multiple layers for better visibility
        canvas.drawPath(p, glowPaint);
        canvas.drawPath(p, paint);
        canvas.drawPath(p, strokePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter old) =>
      !setEquals(old.selected, selected) ||
          !mapEquals(old.paths, paths) ||
          old.scale != scale ||
          old.pulseValue != pulseValue;
}

class _GridPainter extends CustomPainter {
  final double opacity;

  _GridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 0.5;

    const spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}