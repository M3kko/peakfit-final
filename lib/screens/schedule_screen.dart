import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

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

  // Animations
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _glow;
  late Animation<double> _dayCardScale;

  // Current week
  int _currentWeekOffset = 0;
  late DateTime _currentWeekStart;

  // Placeholder workout schedule
  final Map<String, Map<String, dynamic>> _weeklySchedule = {
    'Monday': {
      'title': 'UPPER BODY STRENGTH',
      'focus': ['CHEST', 'SHOULDERS', 'TRICEPS'],
      'duration': '45 MIN',
      'intensity': 'HIGH',
      'completed': false,
    },
    'Tuesday': {
      'title': 'CARDIO & CORE',
      'focus': ['HIIT', 'ABS', 'OBLIQUES'],
      'duration': '30 MIN',
      'intensity': 'MEDIUM',
      'completed': true,
    },
    'Wednesday': {
      'title': 'LOWER BODY POWER',
      'focus': ['QUADS', 'GLUTES', 'CALVES'],
      'duration': '50 MIN',
      'intensity': 'HIGH',
      'completed': false,
    },
    'Thursday': {
      'title': 'ACTIVE RECOVERY',
      'focus': ['YOGA', 'STRETCHING', 'MOBILITY'],
      'duration': '25 MIN',
      'intensity': 'LOW',
      'completed': false,
    },
    'Friday': {
      'title': 'FULL BODY CIRCUIT',
      'focus': ['STRENGTH', 'ENDURANCE', 'POWER'],
      'duration': '40 MIN',
      'intensity': 'HIGH',
      'completed': false,
    },
    'Saturday': {
      'title': 'OUTDOOR ACTIVITY',
      'focus': ['RUN', 'BIKE', 'SWIM'],
      'duration': '60 MIN',
      'intensity': 'MEDIUM',
      'completed': false,
    },
    'Sunday': {
      'title': 'REST DAY',
      'focus': ['RECOVERY', 'NUTRITION', 'HYDRATION'],
      'duration': '-',
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _dayCardController = AnimationController(
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

    _dayCardScale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dayCardController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() {
    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _dayCardController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _dayCardController.dispose();
    super.dispose();
  }

  void _changeWeek(int offset) {
    setState(() {
      _currentWeekOffset += offset;
      _dayCardController.reset();
      _dayCardController.forward();
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
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
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
                        _buildWeekSelector(),
                        Expanded(
                          child: _buildScheduleList(),
                        ),
                        _buildBottomNav(),
                      ],
                    ),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY SCHEDULE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Training Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeWeek(-1),
            icon: Icon(
              Icons.chevron_left,
              color: Colors.white.withOpacity(0.5),
            ),
            padding: EdgeInsets.zero,
          ),
          Column(
            children: [
              Text(
                _currentWeekOffset == 0 ? 'THIS WEEK' :
                _currentWeekOffset > 0 ? 'NEXT WEEK' : 'LAST WEEK',
                style: TextStyle(
                  color: const Color(0xFFD4AF37).withOpacity(0.8),
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getWeekDateRange(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _changeWeek(1),
            icon: Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
            ),
            padding: EdgeInsets.zero,
          ),
        ],
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final workout = _weeklySchedule[day]!;
              final isToday = _isToday(day);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: _buildDayCard(day, workout, isToday),
                    ),
                  );
                },
              );
            },
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
              color: isToday
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isToday
                    ? const Color(0xFFD4AF37).withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
                width: isToday ? 1.5 : 1,
              ),
              boxShadow: isToday ? [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.1 * _glow.value),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ] : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to workout details
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                                      fontSize: 12,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isToday) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'TODAY',
                                        style: TextStyle(
                                          color: const Color(0xFFD4AF37),
                                          fontSize: 10,
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                workout['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          if (workout['completed'] == true)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.green.withOpacity(0.8),
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (workout['focus'] as List<String>).map((focus) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              focus,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoItem(Icons.access_time, workout['duration']),
                          const SizedBox(width: 24),
                          _buildInfoItem(
                            Icons.flash_on,
                            workout['intensity'],
                            color: _getIntensityColor(workout['intensity']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          color: color ?? Colors.white.withOpacity(0.4),
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color ?? Colors.white.withOpacity(0.6),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, false, 0),
          _buildNavItem(Icons.calendar_today, true, 1),
          _buildNavItem(Icons.bar_chart, false, 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (index != 1) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(isActive ? 0.8 : 0.3),
          size: 24,
        ),
      ),
    );
  }
}