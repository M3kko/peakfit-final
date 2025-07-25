import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart' as xml;
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
  // Animation controllers
  late AnimationController _entryController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _pulse;

  // Track selected muscles
  final Set<String> _selectedMuscles = {};

  // Muscle display names
  final Map<String, String> _muscleNames = {
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
    'right-wrist-flexors': 'Right Forearm Flexors',
    'left-wrist-flexors': 'Left Forearm Flexors',
    'right-wrist-extensors': 'Right Forearm Extensors',
    'left-wrist-extensors': 'Left Forearm Extensors',
    'right-hand': 'Right Hand',
    'left-hand': 'Left Hand',
    'right-gluteus-medius': 'Right Glute Med',
    'left-gluteus-medius': 'Left Glute Med',
    'right-gluteus-maximus': 'Right Glutes',
    'left-gluteus-maximus': 'Left Glutes',
    'left-inner-thigh': 'Left Inner Thigh',
    'right-inner-thigh': 'Right Inner Thigh',
    'right-lateral-hamstring': 'Right Hamstring (Outer)',
    'left-lateral-hamstring': 'Left Hamstring (Outer)',
    'right-medial-hamstring': 'Right Hamstring (Inner)',
    'left-medial-hamstring': 'Left Hamstring (Inner)',
    'left-soleus': 'Left Calf (Soleus)',
    'right-soleus': 'Right Calf (Soleus)',
    'left-gastrocnemius': 'Left Calf',
    'right-gastrocnemius': 'Right Calf',
    'left-foot': 'Left Foot',
    'right-foot': 'Right Foot',
    'lower-back': 'Lower Back',
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideUp = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleMuscle(String muscleId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedMuscles.contains(muscleId)) {
        _selectedMuscles.remove(muscleId);
      } else {
        _selectedMuscles.add(muscleId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeIn,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildTitle(),
                                const SizedBox(height: 40),
                                _buildBodyDiagram(),
                                const SizedBox(height: 40),
                                _buildSorenessLegend(),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0A),
            const Color(0xFF0F0F0F),
            const Color(0xFF050505),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
            padding: EdgeInsets.zero,
          ),
          const Spacer(),
          Text(
            'SORENESS CHECK',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'How are you feeling?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w200,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap muscles that feel sore',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyDiagram() {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: InteractiveMusclesSvg(
        selectedMuscles: _selectedMuscles,
        onMuscleTap: _toggleMuscle,
      ),
    );
  }

  Widget _buildSorenessLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECTED MUSCLES',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedMuscles.isEmpty)
            Center(
              child: Text(
                'No muscles selected',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedMuscles.map((muscleId) {
                final muscleName = _muscleNames[muscleId] ?? muscleId;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    muscleName.toUpperCase(),
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
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
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulse.value,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          PreWorkoutScreen(
                            workoutType: widget.workoutType,
                            duration: widget.duration,
                          ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeOutExpo;

                        var tween = Tween(begin: begin, end: end).chain(
                          CurveTween(curve: curve),
                        );

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFE0E0E0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'CONTINUE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.black.withOpacity(0.8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Interactive SVG Widget with Path Parsing
class InteractiveMusclesSvg extends StatefulWidget {
  final Set<String> selectedMuscles;
  final Function(String) onMuscleTap;

  const InteractiveMusclesSvg({
    Key? key,
    required this.selectedMuscles,
    required this.onMuscleTap,
  }) : super(key: key);

  @override
  State<InteractiveMusclesSvg> createState() => _InteractiveMusclesSvgState();
}

class _InteractiveMusclesSvgState extends State<InteractiveMusclesSvg> {
  List<MusclePathData> _musclePaths = [];
  Size _svgSize = const Size(210, 297); // Original SVG size in mm

  @override
  void initState() {
    super.initState();
    _loadSvgPaths();
  }

  Future<void> _loadSvgPaths() async {
    try {
      final String svgString = await rootBundle.loadString('assets/svg/backmuscle-final.svg');
      final document = xml.XmlDocument.parse(svgString);

      final paths = document.findAllElements('path');
      final List<MusclePathData> muscleData = [];

      for (var element in paths) {
        final id = element.getAttribute('id');
        final d = element.getAttribute('d');
        final style = element.getAttribute('style');

        if (id != null && d != null && id != 'path10' &&
            id != 'path29' && id != 'path30' && id != 'path33' &&
            id != 'path39' && id != 'path42') {
          // Parse the path
          final path = parseSvgPathData(d);

          muscleData.add(MusclePathData(
            id: id,
            path: path,
            originalStyle: style ?? '',
          ));
        }
      }

      setState(() {
        _musclePaths = muscleData;
      });
    } catch (e) {
      print('Error loading SVG: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / _svgSize.width;

        return GestureDetector(
          onTapDown: (details) {
            _handleTap(details.localPosition, scale);
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: MuscleSvgPainter(
              musclePaths: _musclePaths,
              selectedMuscles: widget.selectedMuscles,
              scale: scale,
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset position, double scale) {
    // Check which path was tapped
    for (var muscleData in _musclePaths) {
      final scaledPath = Path();
      scaledPath.addPath(muscleData.path, Offset.zero,
          matrix4: Matrix4.identity()..scale(scale).storage);

      if (scaledPath.contains(position)) {
        widget.onMuscleTap(muscleData.id);
        break; // Stop after finding the first hit
      }
    }
  }
}

class MuscleSvgPainter extends CustomPainter {
  final List<MusclePathData> musclePaths;
  final Set<String> selectedMuscles;
  final double scale;

  MuscleSvgPainter({
    required this.musclePaths,
    required this.selectedMuscles,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var muscleData in musclePaths) {
      final isSelected = selectedMuscles.contains(muscleData.id);

      // Create scaled path
      final scaledPath = Path();
      scaledPath.addPath(muscleData.path, Offset.zero,
          matrix4: Matrix4.identity()..scale(scale).storage);

      // Fill paint
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isSelected ? const Color(0xFFFF6B6B) : const Color(0xFFE6E6E6);

      canvas.drawPath(scaledPath, fillPaint);

      // Stroke paint
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black
        ..strokeWidth = 0.564999 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(scaledPath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MuscleSvgPainter oldDelegate) {
    return oldDelegate.selectedMuscles != selectedMuscles ||
        oldDelegate.musclePaths.length != musclePaths.length;
  }
}

class MusclePathData {
  final String id;
  final Path path;
  final String originalStyle;

  MusclePathData({
    required this.id,
    required this.path,
    required this.originalStyle,
  });
}

// SVG Path Parser
Path parseSvgPathData(String d) {
  final path = Path();
  final segments = SvgPathStringParser(d);

  for (final segment in segments) {
    switch (segment.command) {
      case 'M':
      case 'm':
        if (segment.isAbsolute) {
          path.moveTo(segment.targetPoint.x, segment.targetPoint.y);
        } else {
          path.relativeMoveTo(segment.targetPoint.x, segment.targetPoint.y);
        }
        break;
      case 'L':
      case 'l':
        if (segment.isAbsolute) {
          path.lineTo(segment.targetPoint.x, segment.targetPoint.y);
        } else {
          path.relativeLineTo(segment.targetPoint.x, segment.targetPoint.y);
        }
        break;
      case 'H':
      case 'h':
        if (segment.isAbsolute) {
          final currentY = path.getBounds().bottom;
          path.lineTo(segment.targetPoint.x, currentY);
        } else {
          path.relativeLineTo(segment.targetPoint.x, 0);
        }
        break;
      case 'V':
      case 'v':
        if (segment.isAbsolute) {
          final currentX = path.getBounds().right;
          path.lineTo(currentX, segment.targetPoint.y);
        } else {
          path.relativeLineTo(0, segment.targetPoint.y);
        }
        break;
      case 'C':
      case 'c':
        if (segment.isAbsolute) {
          path.cubicTo(
            segment.point1!.x, segment.point1!.y,
            segment.point2!.x, segment.point2!.y,
            segment.targetPoint.x, segment.targetPoint.y,
          );
        } else {
          path.relativeCubicTo(
            segment.point1!.x, segment.point1!.y,
            segment.point2!.x, segment.point2!.y,
            segment.targetPoint.x, segment.targetPoint.y,
          );
        }
        break;
      case 'S':
      case 's':
      // Smooth cubic bezier - simplified implementation
        if (segment.isAbsolute) {
          path.cubicTo(
            segment.point2!.x, segment.point2!.y,
            segment.point2!.x, segment.point2!.y,
            segment.targetPoint.x, segment.targetPoint.y,
          );
        } else {
          path.relativeCubicTo(
            segment.point2!.x, segment.point2!.y,
            segment.point2!.x, segment.point2!.y,
            segment.targetPoint.x, segment.targetPoint.y,
          );
        }
        break;
      case 'Q':
      case 'q':
        if (segment.isAbsolute) {
          path.quadraticBezierTo(
            segment.point1!.x, segment.point1!.y,
            segment.targetPoint.x, segment.targetPoint.y,
          );
        } else {
          path.relativeQuadraticBezierTo(
            segment.point1!.x, segment.point1!.y,
            segment.targetPoint.x, segment.targetPoint.y,
          );
        }
        break;
      case 'T':
      case 't':
      // Smooth quadratic bezier - simplified
        if (segment.isAbsolute) {
          path.quadraticBezierTo(
            segment.targetPoint.x, segment.targetPoint.y,
            segment.targetPoint.x, segment.targetPoint.y,
          );
        } else {
          path.relativeQuadraticBezierTo(
            segment.targetPoint.x, segment.targetPoint.y,
            segment.targetPoint.x, segment.targetPoint.y,
          );
        }
        break;
      case 'A':
      case 'a':
      // Arc - simplified as line for now
        if (segment.isAbsolute) {
          path.lineTo(segment.targetPoint.x, segment.targetPoint.y);
        } else {
          path.relativeLineTo(segment.targetPoint.x, segment.targetPoint.y);
        }
        break;
      case 'Z':
      case 'z':
        path.close();
        break;
    }
  }

  return path;
}

// SVG Path String Parser using path_parsing package
class SvgPathStringParser extends SvgPathNormalizer {
  SvgPathStringParser(String source) : super(source);
}

// Custom implementation of SvgPathNormalizer
class SvgPathNormalizer {
  final String _pathString;
  late final List<PathSegment> _segments;

  SvgPathNormalizer(this._pathString) {
    _segments = _parse();
  }

  List<PathSegment> _parse() {
    final segments = <PathSegment>[];
    final parser = PathParser();

    parser.parsePathString(_pathString, (command, points) {
      segments.add(PathSegment(
        command: command,
        points: points,
      ));
    });

    return segments;
  }

  // Make it iterable
  List<PathSegment> get toList => _segments;
}

// Path segment representation
class PathSegment {
  final String command;
  final List<double> points;

  PathSegment({required this.command, required this.points});

  bool get isAbsolute => command == command.toUpperCase();

  SvgPoint get targetPoint {
    switch (command.toUpperCase()) {
      case 'M':
      case 'L':
      case 'T':
        return SvgPoint(points[points.length - 2], points[points.length - 1]);
      case 'H':
        return SvgPoint(points.last, 0);
      case 'V':
        return SvgPoint(0, points.last);
      case 'C':
      case 'S':
      case 'Q':
        return SvgPoint(points[points.length - 2], points[points.length - 1]);
      case 'A':
        return SvgPoint(points[points.length - 2], points[points.length - 1]);
      default:
        return SvgPoint(0, 0);
    }
  }

  SvgPoint? get point1 {
    switch (command.toUpperCase()) {
      case 'C':
        return SvgPoint(points[0], points[1]);
      case 'Q':
        return SvgPoint(points[0], points[1]);
      default:
        return null;
    }
  }

  SvgPoint? get point2 {
    switch (command.toUpperCase()) {
      case 'C':
        return SvgPoint(points[2], points[3]);
      case 'S':
        return SvgPoint(points[0], points[1]);
      default:
        return null;
    }
  }
}

class SvgPoint {
  final double x;
  final double y;

  SvgPoint(this.x, this.y);
}

// Path parser that handles the actual parsing
class PathParser {
  void parsePathString(String d, void Function(String command, List<double> points) callback) {
    final regex = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])\s*([\d\s,.-]+)?');
    final matches = regex.allMatches(d);

    for (final match in matches) {
      final command = match.group(1)!;
      final pointsString = match.group(2) ?? '';

      final points = <double>[];
      if (pointsString.isNotEmpty) {
        final numbers = RegExp(r'-?\d*\.?\d+').allMatches(pointsString);
        for (final number in numbers) {
          points.add(double.parse(number.group(0)!));
        }
      }

      callback(command, points);
    }
  }
}