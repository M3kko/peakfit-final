import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'workout_screen.dart';

class PreWorkoutScreen extends StatefulWidget {
  final String workoutType;
  final int duration; // in minutes

  const PreWorkoutScreen({
    Key? key,
    required this.workoutType,
    required this.duration,
  }) : super(key: key);

  @override
  State<PreWorkoutScreen> createState() => _PreWorkoutScreenState();
}

class _PreWorkoutScreenState extends State<PreWorkoutScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _entryController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _exerciseCardController;

  // Animations
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _glow;
  late Animation<double> _pulse;
  late Animation<double> _exerciseCardScale;

  // Placeholder exercise data
  final List<Map<String, dynamic>> _exercises = [

    {
      'name': 'LUNGES',
      'sets': '1',
      'reps': '10',
      'type': 'strength',
      'intensity': 'Medium',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _exerciseCardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

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

    _glow = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _exerciseCardScale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _exerciseCardController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() {
    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _exerciseCardController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _exerciseCardController.dispose();
    super.dispose();
  }

  String _getWorkoutTitle() {
    switch (widget.workoutType.toLowerCase()) {
      case 'warmup':
        return 'WARM UP';
      case 'cooldown':
        return 'COOL DOWN';
      case 'strength':
        return 'STRENGTH TRAINING';
      default:
        return widget.workoutType.toUpperCase();
    }
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                _buildWorkoutInfo(),
                                const SizedBox(height: 40),
                                _buildExerciseList(),
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
            'OVERVIEW',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the header
        ],
      ),
    );
  }

  Widget _buildWorkoutInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getWorkoutTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w200,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(Icons.access_time, '${widget.duration} MIN'),
            const SizedBox(width: 16),
            _buildInfoChip(Icons.fitness_center, '${_exercises.length} EXERCISES'),
            const SizedBox(width: 16),
            _buildInfoChip(Icons.local_fire_department, 'MODERATE'),
          ],
        ),
        const SizedBox(height: 24),
        Container(
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
                'FOCUS AREAS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildFocusTag('FULL BODY'),
                  _buildFocusTag('STRENGTH'),
                  _buildFocusTag('ENDURANCE'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.6),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.2),
            const Color(0xFFD4AF37).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: const Color(0xFFD4AF37).withOpacity(0.9),
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXERCISES',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _exerciseCardScale,
          builder: (context, child) {
            return Transform.scale(
              scale: _exerciseCardScale.value,
              child: Column(
                children: _exercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 500 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: _buildExerciseCard(exercise, index),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise['duration'] ?? '${exercise['sets']} sets × ${exercise['reps']} reps',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getIntensityColor(exercise['intensity']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getIntensityColor(exercise['intensity']).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    exercise['intensity'].toUpperCase(),
                    style: TextStyle(
                      color: _getIntensityColor(exercise['intensity']),
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.white;
    }
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
          animation: Listenable.merge([_glow, _pulse]),
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
                          WorkoutScreen(
                            workoutType: widget.workoutType,
                            duration: widget.duration,
                            exercises: _exercises,
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
                        color: Colors.white.withOpacity(0.2 * _glow.value),
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1 * _glow.value),
                        blurRadius: 40,
                        offset: const Offset(0, 0),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'BEGIN WORKOUT',
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