import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

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
  late AnimationController _pulseController;

  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _glow;
  late Animation<double> _pulse;

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

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _scaleIn = Tween<double>(
      begin: 0.8,
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

    _pulse = Tween<double>(
      begin: 0.8,
      end: 1.0,
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
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateTime(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = math.atan2(
      localPosition.dy - center.dy,
      localPosition.dx - center.dx,
    );

    // Convert angle to minutes (0-60)
    double normalizedAngle = (angle + math.pi / 2) % (2 * math.pi);
    if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;

    setState(() {
      _selectedMinutes = (normalizedAngle / (2 * math.pi) * 60).clamp(1, 60);
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 60),
                        _buildTimeSelector(),
                        const SizedBox(height: 80),
                        _buildStartButton(),
                      ],
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
    return Padding(
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
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'How much time do you have?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 24,
            fontWeight: FontWeight.w200,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _getWorkoutTitle(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
      ],
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
              _updateTime(details.localPosition, const Size(280, 280));
              HapticFeedback.selectionClick();
            },
            onPanEnd: (details) {
              setState(() => _isDragging = false);
              _glowController.reverse();
              HapticFeedback.mediumImpact();
            },
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A0A0A),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress arc
                  AnimatedBuilder(
                    animation: _glow,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(280, 280),
                        painter: _CircularProgressPainter(
                          progress: _selectedMinutes / 60,
                          strokeWidth: 3,
                          glowIntensity: _isDragging ? _glow.value : 0.5,
                        ),
                      );
                    },
                  ),

                  // Glow effect
                  if (_isDragging)
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        return Container(
                          width: 240 * _pulse.value,
                          height: 240 * _pulse.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
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
                          fontSize: 72,
                          fontWeight: FontWeight.w200,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MINUTES',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),

                  // Drag handle
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final angle = (_selectedMinutes / 60) * 2 * math.pi - math.pi / 2;
                        final radius = constraints.biggest.width / 2;
                        final handleX = radius + radius * math.cos(angle);
                        final handleY = radius + radius * math.sin(angle);

                        return Stack(
                          children: [
                            Positioned(
                              left: handleX - 12,
                              top: handleY - 12,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: _isDragging ? [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ] : [],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
        // Navigate to workout screen
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
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

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc with glow
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw glow layers
    for (int i = 3; i > 0; i--) {
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.1 * i * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + (i * 4)
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 2.0);

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