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
  late final Animation<double> _fade;
  late final Animation<double> _slideUp;
  late final Animation<double> _pulse;
  late final Animation<double> _switchFade;

  // View state
  bool _showingFront = true;
  bool _isLoading = true;
  String _loadError = '';

  // Raw SVG viewBox dimensions
  static const double _frontVbW = 210.0;
  static const double _frontVbH = 297.0;
  static const double _backVbW = 156.0;
  static const double _backVbH = 236.0;

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
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _switchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 24, end: 0)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _switchFade = CurvedAnimation(parent: _switchCtrl, curve: Curves.easeInOut);

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
      print('Loading front SVG...');
      final frontRaw = await rootBundle.loadString('assets/svg/final-front-muscles.svg');
      final frontDoc = XmlDocument.parse(frontRaw);

      // Check what's in the front SVG
      final frontPaths = frontDoc.findAllElements('path').toList();
      print('Found ${frontPaths.length} paths in front SVG');

      final frontMap = <String, Path>{};
      for (final e in frontPaths) {
        final id = e.getAttribute('id');
        final d = e.getAttribute('d');
        if (id == null || d == null) continue;

        // Skip certain IDs if needed
        if (id == 'path18' || id == 'path19' || id == 'path28' ||
            id == 'path29' || id == 'path30' || id == 'path31' ||
            id == 'path32' || id == 'path33' || id == 'path39' ||
            id == 'path45') continue;

        try {
          final p = parseSvgPathData(d);
          frontMap[id] = p;
          print('Added front path: $id');
        } catch (e) {
          print('Error parsing front path $id: $e');
        }
      }
      print('Parsed ${frontMap.length} front paths');

      // Load back muscles - NO TRANSFORM APPLIED
      print('Loading back SVG...');
      final backRaw = await rootBundle.loadString('assets/svg/backmuscle-final.svg');
      final backDoc = XmlDocument.parse(backRaw);

      final backMap = <String, Path>{};
      final backPaths = backDoc.findAllElements('path').toList();
      print('Found ${backPaths.length} paths in back SVG');

      for (final e in backPaths) {
        final id = e.getAttribute('id');
        final d = e.getAttribute('d');
        if (id == null || d == null) continue;

        try {
          // Parse WITHOUT applying transform - let SVG handle it visually
          final p = parseSvgPathData(d);
          backMap[id] = p;
          print('Added back path: $id');
        } catch (e) {
          print('Error parsing back path $id: $e');
        }
      }
      print('Parsed ${backMap.length} back paths');

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
    super.dispose();
  }

  void _toggle(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_showingFront) {
        if (_selectedFront.contains(id)) {
          _selectedFront.remove(id);
          print('Removed front selection: $id');
        } else {
          _selectedFront.add(id);
          print('Added front selection: $id');
        }
      } else {
        if (_selectedBack.contains(id)) {
          _selectedBack.remove(id);
          print('Removed back selection: $id');
        } else {
          _selectedBack.add(id);
          print('Added back selection: $id');
        }
      }
    });
  }

  void _switchView() {
    HapticFeedback.mediumImpact();
    _switchCtrl.reverse().then((_) {
      setState(() {
        _showingFront = !_showingFront;
        print('Switched to ${_showingFront ? "front" : "back"} view');
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
        _viewToggle(),
        const SizedBox(height: 20),
        if (_isLoading)
          const CircularProgressIndicator(color: Colors.white)
        else if (_loadError.isNotEmpty)
          Text('Error: $_loadError', style: const TextStyle(color: Colors.red))
        else
          FadeTransition(
            opacity: _switchFade,
            child: _diagram(),
          ),
        const SizedBox(height: 40),
        _legend(),
        const SizedBox(height: 100),
      ],
    ),
  );

  Widget _viewToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _showingFront ? null : _switchView,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _showingFront ? Colors.transparent : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: _showingFront ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: _showingFront ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.6),
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          children: [
            Text(
              _showingFront ? 'FRONT VIEW' : 'BACK VIEW',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 80,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: !_showingFront ? null : _switchView,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !_showingFront ? Colors.transparent : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: !_showingFront ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: !_showingFront ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.6),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }



  Widget _diagram() {
    final svgPath = _showingFront
        ? 'assets/svg/final-front-muscles.svg'
        : 'assets/svg/backmuscle-final.svg';

    // Debug info
    print('Showing ${_showingFront ? "front" : "back"} diagram');
    print('Current paths: ${_currentPaths.length}');
    print('Current selection: ${_currentSelection.length}');

    // Use a consistent height for both views
    final screenHeight = MediaQuery.of(context).size.height;
    final diagramHeight = screenHeight * 0.45; // 45% of screen height

    // Calculate width based on each SVG's aspect ratio
    final currentVbW = _showingFront ? _frontVbW : _backVbW;
    final currentVbH = _showingFront ? _frontVbH : _backVbH;
    final aspectRatio = currentVbW / currentVbH;
    final diagramWidth = diagramHeight * aspectRatio;

    return SizedBox(
      height: diagramHeight,
      child: Center(
        child: SizedBox(
          width: diagramWidth,
          height: diagramHeight,
          child: LayoutBuilder(
            builder: (_, constraints) {
              final scale = constraints.maxHeight / currentVbH; // Scale based on height

              return Stack(
                children: [
                  // SVG Display - scaled to same height
                  SvgPicture.asset(
                    svgPath,
                    fit: BoxFit.fill,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),

                  // Custom Paint overlay for highlights
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _HighlightPainter(
                      selected: _currentSelection,
                      paths: _currentPaths,
                      scale: scale,
                    ),
                  ),

                  // Gesture Detector
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) {
                        if (_currentPaths.isEmpty) {
                          print('No paths loaded for tap detection');
                          return;
                        }

                        final lp = d.localPosition;
                        final x = lp.dx / scale;
                        final y = lp.dy / scale;

                        print('Tap at screen: (${lp.dx.toStringAsFixed(1)}, ${lp.dy.toStringAsFixed(1)})');
                        print('Tap at viewBox: (${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})');

                        bool found = false;
                        for (final e in _currentPaths.entries) {
                          if (e.value.contains(Offset(x, y))) {
                            print('Found path: ${e.key}');
                            _toggle(e.key);
                            found = true;
                            break;
                          }
                        }
                        if (!found) {
                          print('No path found at tap location');
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _legend() {
    final currentNames = _showingFront ? _frontNames : _backNames;
    final currentSelection = _showingFront ? _selectedFront : _selectedBack;

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
          Row(
            children: [
              Text('SELECTED MUSCLES',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 1.5, fontSize: 12)),
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
                  child: Text('CLEAR ALL',
                      style: TextStyle(color: Colors.red.shade400, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (currentSelection.isEmpty)
            Center(
              child: Text('No muscles selected',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentSelection.map((id) {
                final name = currentNames[id] ?? id;
                return Chip(
                  label: Text(name.toUpperCase(),
                      style: TextStyle(color: Colors.red.shade300, fontSize: 11, fontWeight: FontWeight.w500)),
                  backgroundColor: Colors.red.withOpacity(0.15),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  deleteIcon: Icon(Icons.close, size: 14, color: Colors.red.shade300),
                  onDeleted: () => _toggle(id),
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

              // Navigate based on whether PreWorkoutScreen accepts soreMuscles parameter
              Navigator.push(
                ctx,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => PreWorkoutScreen(
                    workoutType: widget.workoutType,
                    duration: widget.duration, soreMuscles: [],
                    // Uncomment if PreWorkoutScreen accepts this parameter:
                    // soreMuscles: allSoreMuscles.toList(),
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
                    Text(
                      'CONTINUE',
                      style: TextStyle(
                        color: Colors.black,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.black, size: 20),
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

  _HighlightPainter({
    required this.selected,
    required this.paths,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selected.isEmpty) return;

    final paint = Paint()
      ..color = Colors.red.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.red.withOpacity(0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.save();
    canvas.scale(scale, scale);

    for (final id in selected) {
      final p = paths[id];
      if (p != null) {
        // Draw glow effect
        canvas.drawPath(p, glowPaint);
        // Draw main highlight
        canvas.drawPath(p, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter old) =>
      !setEquals(old.selected, selected) ||
          !mapEquals(old.paths, paths) ||
          old.scale != scale;
}