import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'workout_screen.dart';

class PreWorkoutScreen extends StatefulWidget {
  final String workoutType;
  final int duration; // in minutes
  final List<String> soreMuscles;

  const PreWorkoutScreen({
    Key? key,
    required this.workoutType,
    required this.duration,
    required this.soreMuscles,
  }) : super(key: key);

  @override
  State<PreWorkoutScreen> createState() => _PreWorkoutScreenState();
}

class _PreWorkoutScreenState extends State<PreWorkoutScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _exerciseCardController;
  late AnimationController _upgradeArrowController;
  late AnimationController _tipCardController;

  // Animations
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _pulse;
  late Animation<double> _exerciseCardScale;
  late Animation<double> _upgradeArrowBounce;
  late Animation<double> _tipCardSlide;

  // Simulated recovery data
  final int recoveryScore = 92; // High recovery from WHOOP
  final int sorenessLevel = 2; // Low soreness
  final bool shouldUpgrade = true; // High recovery triggers upgrades

  // Basketball-specific lower body workout (25 minutes total)
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'ANKLE MOBILITY WARM-UP',
      'baseReps': '30 seconds',
      'upgradeReps': '45 seconds',
      'sets': '1',
      'upgradeSets': '2',
      'type': 'warmup',
      'intensity': 'Low',
      'notes': 'Circles, flexion, alphabet',
      'upgraded': true,
    },
    {
      'name': 'JUMP SQUATS',
      'baseReps': '8',
      'upgradeReps': '12',
      'sets': '3',
      'upgradeSets': '4',
      'type': 'power',
      'intensity': 'High',
      'notes': 'Soft landings, explosive up',
      'upgraded': true,
    },
    {
      'name': 'BULGARIAN SPLIT SQUATS',
      'baseReps': '10 each',
      'upgradeReps': '12 each',
      'sets': '2',
      'upgradeSets': '3',
      'type': 'strength',
      'intensity': 'Medium',
      'notes': 'Focus on balance',
      'upgraded': true,
    },
    {
      'name': 'SINGLE-LEG BOX JUMPS',
      'baseReps': '5 each',
      'upgradeReps': '8 each',
      'sets': '2',
      'upgradeSets': '3',
      'type': 'plyometric',
      'intensity': 'High',
      'notes': 'Low box → Medium box',
      'upgradeNotes': 'Progress to medium height',
      'upgraded': true,
    },
    {
      'name': 'LATERAL LUNGES',
      'baseReps': '10 each',
      'upgradeReps': '12 each',
      'sets': '2',
      'upgradeSets': '3',
      'type': 'strength',
      'intensity': 'Medium',
      'notes': 'Deep range of motion',
      'upgraded': true,
    },
    {
      'name': 'CALF RAISES (BILATERAL)',
      'baseReps': '15',
      'upgradeReps': '20 + 10 single-leg',
      'sets': '3',
      'upgradeSets': '4',
      'type': 'strength',
      'intensity': 'Low',
      'notes': 'Slow eccentric phase',
      'upgraded': true,
    },
    {
      'name': 'WALL SIT',
      'baseReps': '30 seconds',
      'upgradeReps': '45 seconds',
      'sets': '2',
      'upgradeSets': '3',
      'type': 'isometric',
      'intensity': 'Medium',
      'notes': 'Maintain 90° angle',
      'upgraded': true,
    },
    {
      'name': 'DEPTH JUMPS',
      'baseReps': '4',
      'upgradeReps': '6',
      'sets': '2',
      'upgradeSets': '3',
      'type': 'plyometric',
      'intensity': 'High',
      'notes': '12" box → 18" box',
      'upgradeNotes': 'Increased height',
      'upgraded': true,
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

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _exerciseCardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _upgradeArrowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _tipCardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _upgradeArrowBounce = Tween<double>(
      begin: 0.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _upgradeArrowController,
      curve: Curves.easeInOut,
    ));

    _tipCardSlide = Tween<double>(
      begin: -20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _tipCardController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() {
    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _exerciseCardController.forward();
      _tipCardController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _exerciseCardController.dispose();
    _upgradeArrowController.dispose();
    _tipCardController.dispose();
    super.dispose();
  }

  String _getWorkoutTitle() {
    switch (widget.workoutType.toLowerCase()) {
      case 'warmup':
        return 'WARM UP';
      case 'cooldown':
        return 'COOL DOWN';
      case 'main':
        return 'LOWER BODY STRENGTH';
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
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRecoveryTip(),
                                const SizedBox(height: 20),
                                _buildWorkoutInfo(),
                                const SizedBox(height: 40),
                                _buildExerciseList(),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF0F0F0F),
            Color(0xFF050505),
          ],
          stops: [0.0, 0.5, 1.0],
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
          Expanded(
            child: Center(
              child: Text(
                'OVERVIEW',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the header
        ],
      ),
    );
  }

  Widget _buildRecoveryTip() {
    return AnimatedBuilder(
      animation: _tipCardSlide,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _tipCardSlide.value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.15),
                  Colors.green.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.green.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'WORKOUT OPTIMIZED',
                            style: TextStyle(
                              color: Colors.green.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '92% RECOVERY',
                              style: TextStyle(
                                color: Colors.green.shade400,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'High recovery detected! Volume and intensity increased for maximum gains.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildInfoChip(Icons.access_time, '${widget.duration} MIN'),
            _buildInfoChip(Icons.fitness_center, '${_exercises.length} EXERCISES'),
            _buildInfoChip(Icons.trending_up, 'ENHANCED', Colors.green),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
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
                  _buildFocusTag('VERTICAL JUMP'),
                  _buildFocusTag('EXPLOSIVENESS'),
                  _buildFocusTag('ANKLE SAFE'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (color ?? Colors.white).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: (color ?? Colors.white).withOpacity(0.6),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: (color ?? Colors.white).withOpacity(0.7),
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
        Row(
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
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: Colors.green,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'UPGRADED',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final bool isUpgraded = exercise['upgraded'] ?? false;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isUpgraded
            ? LinearGradient(
          colors: [
            Colors.green.withOpacity(0.03),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        )
            : null,
        color: !isUpgraded ? Colors.white.withOpacity(0.02) : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUpgraded
              ? Colors.green.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
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
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUpgraded
                              ? Colors.green.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isUpgraded
                                ? Colors.green.withOpacity(0.8)
                                : Colors.white.withOpacity(0.6),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${exercise['sets']} sets × ${exercise['baseReps']}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 14,
                                  decoration: isUpgraded ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (isUpgraded) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _upgradeArrowBounce,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(_upgradeArrowBounce.value, 0),
                                          child: Icon(
                                            Icons.arrow_forward,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${exercise['upgradeSets']} sets × ${exercise['upgradeReps']}',
                                      style: TextStyle(
                                        color: Colors.green.shade400,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          if (exercise['notes'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              exercise['upgradeNotes'] ?? exercise['notes'],
                              style: TextStyle(
                                color: isUpgraded
                                    ? Colors.green.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.4),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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
                if (isUpgraded && index == 3) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: const Color(0xFFD4AF37).withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ankle protection: Focus on soft landings and controlled movements',
                            style: TextStyle(
                              color: const Color(0xFFD4AF37).withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'BEGIN ENHANCED WORKOUT',
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