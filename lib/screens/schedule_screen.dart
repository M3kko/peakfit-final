import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _entryController;
  late AnimationController _glowController;
  late AnimationController _dayCardController;
  late AnimationController _weekTransitionController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _glow;
  late Animation<double> _dayCardScale;
  late Animation<double> _weekTransition;
  late Animation<double> _shimmer;

  // Current week
  int _currentWeekOffset = 0;
  late DateTime _currentWeekStart;

  // Placeholder workout schedule
  final Map<String, Map<String, dynamic>> _weeklySchedule = {
    'Monday': {
      'title': 'UPPER BODY STRENGTH',
      'focus': ['CHEST', 'SHOULDERS', 'TRICEPS'],
      'intensity': 'HIGH',
      'completed': false,
    },
    'Tuesday': {
      'title': 'CARDIO & CORE',
      'focus': ['HIIT', 'ABS', 'OBLIQUES'],
      'intensity': 'MEDIUM',
      'completed': true,
    },
    'Wednesday': {
      'title': 'LOWER BODY POWER',
      'focus': ['QUADS', 'GLUTES', 'CALVES'],
      'intensity': 'HIGH',
      'completed': false,
    },
    'Thursday': {
      'title': 'ACTIVE RECOVERY',
      'focus': ['YOGA', 'STRETCHING', 'MOBILITY'],
      'intensity': 'LOW',
      'completed': false,
    },
    'Friday': {
      'title': 'FULL BODY CIRCUIT',
      'focus': ['STRENGTH', 'ENDURANCE', 'POWER'],
      'intensity': 'HIGH',
      'completed': false,
    },
    'Saturday': {
      'title': 'OUTDOOR ACTIVITY',
      'focus': ['RUN', 'BIKE', 'SWIM'],
      'intensity': 'MEDIUM',
      'completed': false,
    },
    'Sunday': {
      'title': 'REST DAY',
      'focus': ['RECOVERY', 'NUTRITION', 'HYDRATION'],
      'intensity': 'REST',
      'completed': true,
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeWeek();
    _initAnimations();
    _startAnimations();
  }

  void _initializeWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    _currentWeekStart = now.subtract(Duration(days: weekday - 1));
  }

  void _initAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _dayCardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _weekTransitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideUp = Tween<double>(
      begin: 40.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _glow = Tween<double>(
      begin: 0.2,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _dayCardScale = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dayCardController,
      curve: Curves.elasticOut,
    ));

    _weekTransition = CurvedAnimation(
      parent: _weekTransitionController,
      curve: Curves.easeOutExpo,
    );

    _shimmer = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_shimmerController);
  }

  void _startAnimations() {
    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _dayCardController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _dayCardController.dispose();
    _weekTransitionController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekOffset--;
      _weekTransitionController.forward(from: 0);
      _dayCardController.forward(from: 0.8);
    });
    HapticFeedback.lightImpact();
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekOffset++;
      _weekTransitionController.forward(from: 0);
      _dayCardController.forward(from: 0.8);
    });
    HapticFeedback.lightImpact();
  }

  String _getWeekDateRange() {
    final weekStart = _currentWeekStart.add(Duration(days: _currentWeekOffset * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    if (weekStart.month == weekEnd.month) {
      return '${weekStart.day} - ${weekEnd.day} ${months[weekStart.month - 1]}';
    } else {
      return '${weekStart.day} ${months[weekStart.month - 1]} - ${weekEnd.day} ${months[weekEnd.month - 1]}';
    }
  }

  bool _isToday(String dayName) {
    if (_currentWeekOffset != 0) return false;

    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[now.weekday - 1] == dayName;
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFFF6B6B);
      case 'MEDIUM':
        return const Color(0xFFFFB84D);
      case 'LOW':
        return const Color(0xFF4ECDC4);
      case 'REST':
        return const Color(0xFFD4AF37);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          _buildBackground(),
          _buildGlassOverlay(),
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeIn,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: _buildScheduleContent(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0A),
                Color(0xFF1A1A1A),
                Color(0xFF0F0F0F),
              ],
            ),
          ),
        ),
        // Animated gradient orbs
        Positioned(
          top: -100,
          right: -100,
          child: AnimatedBuilder(
            animation: _glow,
            builder: (context, child) {
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.1 * _glow.value),
                      const Color(0xFFD4AF37).withOpacity(0.05 * _glow.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: AnimatedBuilder(
            animation: _glow,
            builder: (context, child) {
              return Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.08 * _glow.value),
                      const Color(0xFFD4AF37).withOpacity(0.03 * _glow.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGlassOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        color: Colors.black.withOpacity(0.2),
      ),
    );
  }

  Widget _buildScheduleContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 16),
        _buildHeader(),
        const SizedBox(height: 36),
        _buildWeekSelector(),
        const SizedBox(height: 36),
        _buildScheduleList(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _shimmer,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.6),
                          const Color(0xFFD4AF37),
                          Colors.white.withOpacity(0.6),
                        ],
                        stops: [
                          _shimmer.value - 0.3,
                          _shimmer.value,
                          _shimmer.value + 0.3,
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'WEEKLY PLAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Training Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekSelector() {
    return AnimatedBuilder(
      animation: _weekTransition,
      builder: (context, child) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Previous week button
                    _buildWeekNavButton(
                      icon: Icons.chevron_left,
                      onTap: _goToPreviousWeek,
                      isEnabled: true,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            switchInCurve: Curves.easeOutExpo,
                            switchOutCurve: Curves.easeInExpo,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.5),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _getWeekDateRange(),
                              key: ValueKey<String>(_getWeekDateRange()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _currentWeekOffset == 0
                                  ? const Color(0xFFD4AF37).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _currentWeekOffset == 0
                                  ? 'CURRENT WEEK'
                                  : _currentWeekOffset < 0
                                  ? '${-_currentWeekOffset} WEEK${-_currentWeekOffset > 1 ? 'S' : ''} AGO'
                                  : '${_currentWeekOffset} WEEK${_currentWeekOffset > 1 ? 'S' : ''} AHEAD',
                              style: TextStyle(
                                color: _currentWeekOffset == 0
                                    ? const Color(0xFFD4AF37)
                                    : Colors.white.withOpacity(0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Next week button
                    _buildWeekNavButton(
                      icon: Icons.chevron_right,
                      onTap: _goToNextWeek,
                      isEnabled: _currentWeekOffset < 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isEnabled ? 1.0 : 0.3,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(isEnabled ? 0.2 : 0.05),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Icon(
                icon,
                color: Colors.white.withOpacity(isEnabled ? 0.8 : 0.2),
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return AnimatedBuilder(
      animation: _dayCardScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _dayCardScale.value,
          child: Column(
            children: days.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final workout = _weeklySchedule[day]!;
              final isToday = _isToday(day);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 600 + (index * 80)),
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: _buildDayCard(day, workout, isToday),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDayCard(String day, Map<String, dynamic> workout, bool isToday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isToday
                    ? [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.06),
                ]
                    : [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isToday
                    ? const Color(0xFFD4AF37).withOpacity(0.4)
                    : Colors.white.withOpacity(0.08),
                width: isToday ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isToday
                      ? const Color(0xFFD4AF37).withOpacity(0.15 * _glow.value)
                      : Colors.black.withOpacity(0.3),
                  blurRadius: isToday ? 30 : 20,
                  spreadRadius: isToday ? 2 : 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Navigate to workout details
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        day.toUpperCase(),
                                        style: TextStyle(
                                          color: isToday
                                              ? const Color(0xFFD4AF37)
                                              : Colors.white.withOpacity(0.5),
                                          fontSize: 11,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (isToday) ...[
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFD4AF37),
                                                Color(0xFFB8941F),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFD4AF37).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'TODAY',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 9,
                                              letterSpacing: 1.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    workout['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              if (workout['completed'] == true)
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF4ECDC4).withOpacity(0.3),
                                        const Color(0xFF4ECDC4).withOpacity(0.1),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF4ECDC4).withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4ECDC4).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF4ECDC4),
                                    size: 22,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: (workout['focus'] as List<String>).map((focus) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.1),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  focus,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getIntensityColor(workout['intensity']).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getIntensityColor(workout['intensity']).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: _getIntensityColor(workout['intensity']),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  workout['intensity'],
                                  style: TextStyle(
                                    color: _getIntensityColor(workout['intensity']),
                                    fontSize: 11,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}