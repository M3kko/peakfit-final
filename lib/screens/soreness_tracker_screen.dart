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

  // SVG viewBox dimensions (both SVGs have same viewBox)
  static const double _svgViewBoxWidth = 210.0;
  static const double _svgViewBoxHeight = 297.0;

  // Parsed paths and transforms for both views
  Map<String, Path> _frontPaths = {};
  Map<String, Path> _backPaths = {};
  Matrix4? _frontTransform;
  Matrix4? _backTransform;

  final Set<String> _selectedFront = {};
  final Set<String> _selectedBack = {};
  final Map<String, int> _sorenessLevels = {}; // Store soreness levels for all muscles
  String? _showingSorenessPopup; // Track which muscle is showing popup

  // Get current selection based on view
  Set<String> get _currentSelection => _showingFront ? _selectedFront : _selectedBack;
  Map<String, Path> get _currentPaths => _showingFront ? _frontPaths : _backPaths;
  Matrix4? get _currentTransform => _showingFront ? _frontTransform : _backTransform;

  // Muscle display names for front (mirrored - anatomical right is user's left)
  static const Map<String, String> _frontNames = {
    'neck': 'Neck',
    'upper-trapezius-left': 'Right Upper Traps',  // Mirrored
    'upper-trapezius-right': 'Left Upper Traps',  // Mirrored
    'upper-pectoralis-right': 'Left Upper Chest',  // Mirrored
    'upper-pectoralis-left': 'Right Upper Chest',  // Mirrored
    'anterior-deltoid-right': 'Left Front Delt',  // Mirrored
    'anterior-deltoid-left': 'Right Front Delt',  // Mirrored
    'lateral-deltoid-right': 'Left Side Delt',  // Mirrored
    'lateral-deltoid-left': 'Right Side Delt',  // Mirrored
    'mid-lower-pectoralis-right': 'Left Lower Chest',  // Mirrored
    'mid-lower-pectoralis-left': 'Right Lower Chest',  // Mirrored
    'obliques-left': 'Right Obliques',  // Mirrored
    'obliques-right': 'Left Obliques',  // Mirrored
    'short-head-bicep-left': 'Right Bicep (Short)',  // Mirrored
    'long-head-bicep-left': 'Right Bicep (Long)',  // Mirrored
    'short-head-bicep-right': 'Left Bicep (Short)',  // Mirrored
    'long-head-bicep-right': 'Left Bicep (Long)',  // Mirrored
    'wrist-extensors-left': 'Right Wrist Extensors',  // Mirrored
    'wrist-flexors-left': 'Right Wrist Flexors',  // Mirrored
    'wrist-left': 'Right Wrist',  // Mirrored
    'wrist-extensors-right': 'Left Wrist Extensors',  // Mirrored
    'wrist-flexors-right': 'Left Wrist Flexors',  // Mirrored
    'wrist-right': 'Left Wrist',  // Mirrored
    'groin': 'Groin',
    'lower-abdominals': 'Lower Abs',
    'upper-abdominals': 'Upper Abs',
    'outer-quadricep-right': 'Left Outer Quad',  // Mirrored
    'outer-quadricep-left': 'Right Outer Quad',  // Mirrored
    'rectus-femoris-right': 'Left Rectus Femoris',  // Mirrored
    'rectus-femoris-left': 'Right Rectus Femoris',  // Mirrored
    'inner-quadricep-right': 'Left Inner Quad',  // Mirrored
    'inner-quadricep-left': 'Right Inner Quad',  // Mirrored
    'inner-thigh-right': 'Left Inner Thigh',  // Mirrored
    'inner-thigh-left': 'Right Inner Thigh',  // Mirrored
    'tibialis-right': 'Left Tibialis',  // Mirrored
    'tibialis-left': 'Right Tibialis',  // Mirrored
    'gastrocnemius-right': 'Left Calf',  // Mirrored
    'gastrocnemius-left': 'Right Calf',  // Mirrored
    'soleus-right': 'Left Soleus',  // Mirrored
    'soleus-left': 'Right Soleus',  // Mirrored
    'foot-right': 'Left Foot',  // Mirrored
    'foot-left': 'Right Foot',  // Mirrored
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

      // Load and parse front SVG
      final frontRaw = await rootBundle.loadString('assets/svg/final-front-muscles.svg');
      final frontDoc = XmlDocument.parse(frontRaw);
      final frontData = _parseSvgPaths(frontDoc);

      // Load and parse back SVG
      final backRaw = await rootBundle.loadString('assets/svg/backmuscle-final.svg');
      final backDoc = XmlDocument.parse(backRaw);
      final backData = _parseSvgPaths(backDoc);

      if (!mounted) return;

      setState(() {
        _frontPaths = frontData['paths'] as Map<String, Path>;
        _frontTransform = frontData['transform'] as Matrix4?;
        _backPaths = backData['paths'] as Map<String, Path>;
        _backTransform = backData['transform'] as Matrix4?;
        _isLoading = false;
      });

      // Debug output
      print('Front paths loaded: ${_frontPaths.length}');
      print('Front transform: $_frontTransform');
      print('Back paths loaded: ${_backPaths.length}');
      print('Back transform: $_backTransform');

    } catch (e) {
      print('Error loading paths: $e');
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _parseSvgPaths(XmlDocument doc) {
    final paths = <String, Path>{};
    Matrix4? groupTransform;

    // Find the layer1 group and extract its transform
    final groups = doc.findAllElements('g');
    for (final group in groups) {
      final id = group.getAttribute('id');
      if (id == 'layer1') {
        final transformStr = group.getAttribute('transform');
        if (transformStr != null && transformStr.contains('translate')) {
          // Parse translate transform
          final regex = RegExp(r'translate\(([-\d.]+),([-\d.]+)\)');
          final match = regex.firstMatch(transformStr);
          if (match != null) {
            final tx = double.parse(match.group(1)!);
            final ty = double.parse(match.group(2)!);
            groupTransform = Matrix4.identity()..translate(tx, ty);
            print('Found transform: translate($tx, $ty)');
          }
        }

        // Parse paths within this group
        for (final element in group.findAllElements('path')) {
          final pathId = element.getAttribute('id');
          final d = element.getAttribute('d');

          if (pathId == null || d == null) continue;

          // Skip numbered paths (path18, path19, etc.)
          if (RegExp(r'^path\d+$').hasMatch(pathId)) continue;

          try {
            var path = parseSvgPathData(d);

            // Apply the group transform to the path
            if (groupTransform != null) {
              path = path.transform(groupTransform.storage);
            }

            paths[pathId] = path;
          } catch (e) {
            print('Error parsing path $pathId: $e');
          }
        }
      }
    }

    print('Parsed ${paths.length} paths');
    return {
      'paths': paths,
      'transform': groupTransform,
    };
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
          _sorenessLevels.remove(id); // Remove soreness level
          _showingSorenessPopup = null;
        } else {
          _selectedFront.add(id);
          _sorenessLevels[id] = 5; // Default soreness level
          _showingSorenessPopup = id; // Show popup for this muscle
        }
      } else {
        if (_selectedBack.contains(id)) {
          _selectedBack.remove(id);
          _sorenessLevels.remove(id); // Remove soreness level
          _showingSorenessPopup = null;
        } else {
          _selectedBack.add(id);
          _sorenessLevels[id] = 5; // Default soreness level
          _showingSorenessPopup = id; // Show popup for this muscle
        }
      }
    });
  }

  void _setSorenessLevel(String id, int level) {
    setState(() {
      _sorenessLevels[id] = level;
    });
  }

  void _closeSorenessPopup() {
    setState(() {
      _showingSorenessPopup = null;
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

  Widget _diagram() {
    final svgPath = _showingFront
        ? 'assets/svg/final-front-muscles.svg'
        : 'assets/svg/backmuscle-final.svg';

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate display size - reduced to make room for legend
    final maxHeight = screenHeight * 0.45; // Reduced from 0.6
    final maxWidth = screenWidth - 40;

    final aspectRatio = _svgViewBoxWidth / _svgViewBoxHeight;
    double displayHeight = maxHeight;
    double displayWidth = displayHeight * aspectRatio;

    if (displayWidth > maxWidth) {
      displayWidth = maxWidth;
      displayHeight = displayWidth / aspectRatio;
    }

    return Container(
      height: displayHeight + 20,
      width: screenWidth,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // SVG Display
          SizedBox(
            width: displayWidth,
            height: displayHeight,
            child: SvgPicture.asset(
              svgPath,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),

          // Custom Paint overlay with animation
          SizedBox(
            width: displayWidth,
            height: displayHeight,
            child: AnimatedBuilder(
              animation: _selectedPulse,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(displayWidth, displayHeight),
                  painter: _HighlightPainter(
                    selected: _currentSelection,
                    paths: _currentPaths,
                    viewBoxWidth: _svgViewBoxWidth,
                    viewBoxHeight: _svgViewBoxHeight,
                    displayWidth: displayWidth,
                    displayHeight: displayHeight,
                    pulseValue: _selectedPulse.value,
                  ),
                );
              },
            ),
          ),

          // Gesture Detector
          SizedBox(
            width: displayWidth,
            height: displayHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (_currentPaths.isEmpty) return;

                // Convert tap position to SVG coordinates
                final scaleX = _svgViewBoxWidth / displayWidth;
                final scaleY = _svgViewBoxHeight / displayHeight;

                final svgX = details.localPosition.dx * scaleX;
                final svgY = details.localPosition.dy * scaleY;

                // Check hit test
                for (final entry in _currentPaths.entries) {
                  if (entry.value.contains(Offset(svgX, svgY))) {
                    _toggle(entry.key);
                    print('Hit: ${entry.key}');
                    break;
                  }
                }
              },
            ),
          ),

          // Soreness Level Popup
          if (_showingSorenessPopup != null)
            Positioned(
              top: displayHeight / 2 - 60,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SORENESS LEVEL',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: _closeSorenessPopup,
                          child: Icon(
                            Icons.close,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(10, (index) {
                        final level = index + 1;
                        final isSelected = _sorenessLevels[_showingSorenessPopup] == level;
                        return GestureDetector(
                          onTap: () {
                            _setSorenessLevel(_showingSorenessPopup!, level);
                            HapticFeedback.lightImpact();
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _closeSorenessPopup();
                            });
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.red
                                  : Colors.red.withOpacity(0.1 + (level * 0.08)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.red
                                    : Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$level',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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
        const SizedBox(height: 16), // Reduced from 32
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

  Widget _legend() {
    final currentNames = _showingFront ? _frontNames : _backNames;
    final currentSelection = _showingFront ? _selectedFront : _selectedBack;

    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.white.withOpacity(0.5), size: 14),
                    const SizedBox(width: 6),
                    Text('SELECTED',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 1.2, fontSize: 10)),
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
                      // Clear soreness levels for current view
                      _sorenessLevels.removeWhere((key, value) =>
                          currentSelection.contains(key));
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text('CLEAR',
                        style: TextStyle(color: Colors.red.shade300, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentSelection.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.white.withOpacity(0.2), size: 24),
                  const SizedBox(height: 6),
                  Text('Tap muscles to track soreness',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                ],
              ),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: currentSelection.map((id) {
                final name = currentNames[id] ?? id;
                final sorenessLevel = _sorenessLevels[id] ?? 5;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: GestureDetector(
                        onTap: () => _toggle(id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Text(
                                  '${name.toUpperCase()} ($sorenessLevel)',
                                  style: TextStyle(
                                    color: Colors.red.shade300,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.close, size: 12, color: Colors.red.shade300),
                            ],
                          ),
                        ),
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

// Highlight painter with subtle animation
class _HighlightPainter extends CustomPainter {
  final Set<String> selected;
  final Map<String, Path> paths;
  final double viewBoxWidth;
  final double viewBoxHeight;
  final double displayWidth;
  final double displayHeight;
  final double pulseValue;

  _HighlightPainter({
    required this.selected,
    required this.paths,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.displayWidth,
    required this.displayHeight,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selected.isEmpty) return;

    // Brighter, more vibrant red with stronger presence
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.5 + pulseValue * 0.2) // Stronger base opacity
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.red.withOpacity(0.3) // Stronger glow
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Calculate scale from viewBox to display size
    final scaleX = displayWidth / viewBoxWidth;
    final scaleY = displayHeight / viewBoxHeight;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    for (final id in selected) {
      final path = paths[id];
      if (path != null) {
        // Draw only glow and fill - no stroke for cleaner look
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter old) =>
      !setEquals(old.selected, selected) ||
          !mapEquals(old.paths, paths) ||
          old.viewBoxWidth != viewBoxWidth ||
          old.viewBoxHeight != viewBoxHeight ||
          old.displayWidth != displayWidth ||
          old.displayHeight != displayHeight ||
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