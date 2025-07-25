import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'preworkout_screen.dart';

class TimeSelectionScreen extends StatefulWidget {
  final String workoutType;

  const TimeSelectionScreen({
    Key? key,
    required this.workoutType,
  }) : super(key: key);

  @override
  State<TimeSelectionScreen> createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends State<TimeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _glowController;

  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _glow;

  double _selectedMinutes = 30;
  bool _isDragging = false;

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

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _scaleIn = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    ));

    _glow = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _updateTime(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // Calculate angle from center
    double angle = math.atan2(dy, dx);

    // Convert to 0-2π range starting from top
    angle = (angle + math.pi / 2) % (2 * math.pi);
    if (angle < 0) angle += 2 * math.pi;

    // Convert to minutes
    double minutes = (angle / (2 * math.pi)) * 60;

    // Round to nearest 5
    minutes = (minutes / 5).round() * 5;

    // Strict boundary enforcement
    if (_selectedMinutes >= 60) {
      // At 60, only allow backwards movement
      if (minutes < 30 || minutes >= 60) {
        return; // Don't update if trying to go forward from 60
      }
    } else if (_selectedMinutes <= 0) {
      // At 0, only allow forward movement
      if (minutes > 30) {
        return; // Don't update if trying to go backward from 0
      }
    } else {
      // Normal range - prevent wrapping
      if (_selectedMinutes <= 5 && minutes > 55) {
        minutes = 0;
      } else if (_selectedMinutes >= 55 && minutes < 5) {
        minutes = 60;
      }
    }

    setState(() {
      _selectedMinutes = minutes.clamp(0, 60);
    });
  }

  String _getWorkoutTitle() {
    switch (widget.workoutType.toLowerCase()) {
      case 'warmup':
        return 'WARM UP';
      case 'cooldown':
        return 'COOL DOWN';
      case 'strength':
        return 'WORKOUT';
      default:
        return widget.workoutType.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeIn,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeIn.value,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          _buildTitle(),
                          const Spacer(flex: 1),
                          _buildTimeSelector(),
                          const Spacer(flex: 2),
                          _buildStartButton(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(24),
      child: IconButton(
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
    );
  }

  Widget _buildTitle() {
    return Text(
      'How much time\ndo you have?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 28,
        fontWeight: FontWeight.w200,
        letterSpacing: 0.5,
        height: 1.3,
      ),
    );
  }

  Widget _buildTimeSelector() {
    return AnimatedBuilder(
      animation: _scaleIn,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleIn.value,
          child: GestureDetector(
            onPanStart: (details) {
              setState(() => _isDragging = true);
              _glowController.forward();
              HapticFeedback.lightImpact();
            },
            onPanUpdate: (details) {
              _updateTime(details.localPosition, const Size(360, 360));
            },
            onPanEnd: (details) {
              setState(() => _isDragging = false);
              _glowController.reverse();
              HapticFeedback.mediumImpact();
            },
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none, // Allow content to extend beyond bounds
                children: [
                  // Background circle
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // Progress arc
                  AnimatedBuilder(
                    animation: _glow,
                    builder: (context, child) {
                      return SizedBox(
                        width: 320,
                        height: 320,
                        child: CustomPaint(
                          painter: _CircularProgressPainter(
                            progress: _selectedMinutes / 60,
                            strokeWidth: 3,
                            glowIntensity: _isDragging ? _glow.value : 0.5,
                          ),
                        ),
                      );
                    },
                  ),

                  // Center content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedMinutes.round().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 84,
                          fontWeight: FontWeight.w100,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MINUTES',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),

                  // Drag handle
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: Stack(
                      clipBehavior: Clip.none, // Allow handle to extend beyond bounds
                      children: [
                        AnimatedBuilder(
                          animation: Listenable.merge([_fadeIn]),
                          builder: (context, child) {
                            final angle = (_selectedMinutes / 60) * 2 * math.pi - math.pi / 2;
                            final radius = 160;
                            final handleX = radius + radius * math.cos(angle);
                            final handleY = radius + radius * math.sin(angle);

                            return Positioned(
                              left: handleX - 15,
                              top: handleY - 15,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(_isDragging ? 0.6 : 0.3),
                                      blurRadius: _isDragging ? 30 : 15,
                                      spreadRadius: _isDragging ? 10 : 5,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SorenessTrackerScreen(
                  workoutType: widget.workoutType,
                  duration: _selectedMinutes.round(),
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 0),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          'START ${_getWorkoutTitle()}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final double glowIntensity;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (progress <= 0) return;

    // Progress arc with glow
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw glow layers
    for (int i = 3; i > 0; i--) {
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.08 * i * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + (i * 6)
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 3.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        glowPaint,
      );
    }

    // Draw main progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        glowIntensity != oldDelegate.glowIntensity;
  }
}