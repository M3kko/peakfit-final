import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  DateTime? _accountCreatedDate;
  bool _isFirstWeek = false;

  // Basketball-specific workout schedule for vertical jump & posture improvement
  // Includes ankle-friendly modifications
  final Map<String, Map<String, dynamic>> _basketballSchedule = {
    'Day 1': {
      'title': 'EXPLOSIVE POWER',
      'focus': ['PLYOMETRICS', 'GLUTES', 'CORE'],
      'intensity': 'HIGH',
      'completed': false,
      'exercises': [
        'Box Jumps (modified height)',
        'Single-Leg Bounds',
        'Broad Jumps',
        'Plank Variations',
        'Bird Dogs'
      ],
      'notes': 'Focus on soft landings to protect ankle'
    },
    'Day 2': {
      'title': 'POSTURE & STABILITY',
      'focus': ['UPPER BACK', 'SHOULDERS', 'BALANCE'],
      'intensity': 'MEDIUM',
      'completed': false,
      'exercises': [
        'Wall Angels',
        'Y-T-W Raises',
        'Single-Leg Balance',
        'Band Pull-Aparts',
        'Cat-Cow Stretches'
      ],
      'notes': 'Emphasize shoulder blade control'
    },
    'Day 3': {
      'title': 'LOWER BODY STRENGTH',
      'focus': ['QUADS', 'HAMSTRINGS', 'CALVES'],
      'intensity': 'HIGH',
      'completed': false,
      'exercises': [
        'Jump Squats',
        'Bulgarian Split Squats',
        'Nordic Curls (assisted)',
        'Calf Raises (bilateral)',
        'Ankle Mobility Work'
      ],
      'notes': 'Build bilateral strength first'
    },
    'Day 4': {
      'title': 'ACTIVE RECOVERY',
      'focus': ['MOBILITY', 'FLEXIBILITY', 'ANKLE REHAB'],
      'intensity': 'LOW',
      'completed': false,
      'exercises': [
        'Dynamic Stretching',
        'Foam Rolling',
        'Ankle Circles & Flexion',
        'Hip Mobility',
        'Light Shooting Practice'
      ],
      'notes': 'Focus on ankle rehabilitation'
    },
    'Day 5': {
      'title': 'VERTICAL FOCUS',
      'focus': ['JUMP TECHNIQUE', 'EXPLOSIVENESS', 'CORE'],
      'intensity': 'HIGH',
      'completed': false,
      'exercises': [
        'Depth Jumps (low height)',
        'Medicine Ball Slams',
        'Squat Jumps',
        'Hollow Body Holds',
        'Russian Twists'
      ],
      'notes': 'Progressive jump height based on ankle comfort'
    },
    'Day 6': {
      'title': 'BASKETBALL SKILLS',
      'focus': ['AGILITY', 'COORDINATION', 'ENDURANCE'],
      'intensity': 'MEDIUM',
      'completed': false,
      'exercises': [
        'Ladder Drills',
        'Defensive Slides',
        'Sprint Intervals',
        'Ball Handling',
        'Post Work'
      ],
      'notes': 'Sport-specific movement patterns'
    },
    'Day 7': {
      'title': 'REST & RECOVERY',
      'focus': ['RECOVERY', 'NUTRITION', 'MENTAL'],
      'intensity': 'REST',
      'completed': false,
      'exercises': [
        'Light Walking',
        'Meditation',
        'Film Study',
        'Hydration Focus',
        'Sleep Optimization'
      ],
      'notes': 'Complete rest or light activity only'
    },
  };

  // Standard weekly schedule (after first week)
  final Map<String, Map<String, dynamic>> _weeklySchedule = {
    'Monday': {
      'title': 'EXPLOSIVE POWER',
      'focus': ['PLYOMETRICS', 'GLUTES', 'CORE'],
      'intensity': 'HIGH',
      'completed': false,
    },
    'Tuesday': {
      'title': 'POSTURE & STABILITY',
      'focus': ['UPPER BACK', 'SHOULDERS', 'BALANCE'],
      'intensity': 'MEDIUM',
      'completed': false,
    },
    'Wednesday': {
      'title': 'LOWER BODY STRENGTH',
      'focus': ['QUADS', 'HAMSTRINGS', 'CALVES'],
      'intensity': 'HIGH',
      'completed': false,
    },
    'Thursday': {
      'title': 'ACTIVE RECOVERY',
      'focus': ['MOBILITY', 'FLEXIBILITY', 'ANKLE REHAB'],
      'intensity': 'LOW',
      'completed': false,
    },
    'Friday': {
      'title': 'VERTICAL FOCUS',
      'focus': ['JUMP TECHNIQUE', 'EXPLOSIVENESS', 'CORE'],
      'intensity': 'HIGH',
      'completed': false,
    },
    'Saturday': {
      'title': 'BASKETBALL SKILLS',
      'focus': ['AGILITY', 'COORDINATION', 'ENDURANCE'],
      'intensity': 'MEDIUM',
      'completed': false,
    },
    'Sunday': {
      'title': 'REST & RECOVERY',
      'focus': ['RECOVERY', 'NUTRITION', 'MENTAL'],
      'intensity': 'REST',
      'completed': false,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadAccountCreatedDate();
    _initializeWeek();
    _initAnimations();
    _startAnimations();
  }

  Future<void> _loadAccountCreatedDate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()?['createdAt'] != null) {
          setState(() {
            _accountCreatedDate = (doc.data()!['createdAt'] as Timestamp).toDate();
            _checkIfFirstWeek();
          });
        }
      } catch (e) {
        print('Error loading account creation date: $e');
      }
    }
  }

  void _checkIfFirstWeek() {
    if (_accountCreatedDate != null) {
      final now = DateTime.now();
      final daysSinceCreation = now.difference(_accountCreatedDate!).inDays;

      // Check if we're still in the first week (0-6 days since creation)
      _isFirstWeek = daysSinceCreation < 7 && _currentWeekOffset == 0;
    }
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
      duration: const Duration(seconds: 2),
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

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekOffset--;
      _checkIfFirstWeek();
      _dayCardController.reset();
      _dayCardController.forward();
    });
    HapticFeedback.lightImpact();
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekOffset++;
      _checkIfFirstWeek();
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

  List<Map<String, dynamic>> _getCurrentSchedule() {
    if (_isFirstWeek && _accountCreatedDate != null) {
      // First week: Start from account creation day
      final creationWeekday = _accountCreatedDate!.weekday;
      final daysSinceCreation = DateTime.now().difference(_accountCreatedDate!).inDays;

      List<Map<String, dynamic>> schedule = [];

      // Add days from creation day to end of week
      for (int i = 0; i < 7; i++) {
        final dayNumber = i + 1;
        final dayData = Map<String, dynamic>.from(_basketballSchedule['Day $dayNumber']!);

        // Calculate actual date for this day
        final dayDate = _accountCreatedDate!.add(Duration(days: i));
        final isToday = _isToday(dayDate);
        final isPast = i < daysSinceCreation;

        dayData['dayName'] = 'Day $dayNumber';
        dayData['date'] = dayDate;
        dayData['isToday'] = isToday;
        dayData['isPast'] = isPast;

        schedule.add(dayData);
      }

      return schedule;
    } else {
      // Regular weeks: Monday to Sunday
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      List<Map<String, dynamic>> schedule = [];

      for (int i = 0; i < days.length; i++) {
        final dayName = days[i];
        final dayData = Map<String, dynamic>.from(_weeklySchedule[dayName]!);

        final weekStart = _currentWeekStart.add(Duration(days: _currentWeekOffset * 7));
        final dayDate = weekStart.add(Duration(days: i));

        dayData['dayName'] = dayName;
        dayData['date'] = dayDate;
        dayData['isToday'] = _isToday(dayDate);
        dayData['isPast'] = dayDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

        schedule.add(dayData);
      }

      return schedule;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildWeekSelector(),
                          const SizedBox(height: 24),
                          _buildProgramInfo(),
                          const SizedBox(height: 32),
                          _buildScheduleList(),
                          const SizedBox(height: 100),
                        ],
                      ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BASKETBALL TRAINING',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'VERTICAL & POSTURE FOCUS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFD4AF37).withOpacity(0.8),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_basketball,
            color: const Color(0xFFD4AF37).withOpacity(0.8),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FORWARD POSITION',
                  style: TextStyle(
                    color: const Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bodyweight • Ankle-Safe • Progressive',
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
    );
  }

  Widget _buildWeekSelector() {
    final weekLabel = _isFirstWeek ? 'WEEK 1 - ONBOARDING' :
    _currentWeekOffset == 0 ? 'CURRENT WEEK' :
    _currentWeekOffset < 0 ? '${-_currentWeekOffset} WEEK${-_currentWeekOffset > 1 ? 'S' : ''} AGO' :
    '${_currentWeekOffset} WEEK${_currentWeekOffset > 1 ? 'S' : ''} AHEAD';

    return Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous week button
          GestureDetector(
            onTap: _goToPreviousWeek,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.chevron_left,
                color: Colors.white.withOpacity(0.6),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Week info
          Expanded(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _getWeekDateRange(),
                    key: ValueKey<String>(_getWeekDateRange()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  weekLabel,
                  style: TextStyle(
                    color: _isFirstWeek || _currentWeekOffset == 0
                        ? const Color(0xFFD4AF37).withOpacity(0.8)
                        : Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Next week button
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _currentWeekOffset < 0 ? 1.0 : 0.2,
            child: GestureDetector(
              onTap: _currentWeekOffset < 0 ? _goToNextWeek : null,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(_currentWeekOffset < 0 ? 0.6 : 0.2),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    final schedule = _getCurrentSchedule();

    return AnimatedBuilder(
      animation: _dayCardScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _dayCardScale.value,
          child: Column(
            children: schedule.asMap().entries.map((entry) {
              final index = entry.key;
              final dayData = entry.value;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 500 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: _buildDayCard(dayData),
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

  Widget _buildDayCard(Map<String, dynamic> dayData) {
    final isToday = dayData['isToday'] ?? false;
    final isPast = dayData['isPast'] ?? false;
    final dayName = dayData['dayName'];

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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday
                    ? const Color(0xFFD4AF37).withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: isToday
                  ? [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.1 * _glow.value),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to workout details
                },
                borderRadius: BorderRadius.circular(16),
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
                                    dayName.toUpperCase(),
                                    style: TextStyle(
                                      color: isToday
                                          ? const Color(0xFFD4AF37)
                                          : Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w400,
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
                                dayData['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          if (dayData['completed'] == true || isPast)
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
                        children: (dayData['focus'] as List<String>).map((focus) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
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
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: _getIntensityColor(dayData['intensity']),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dayData['intensity'],
                            style: TextStyle(
                              color: _getIntensityColor(dayData['intensity']),
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (dayData['intensity'] == 'HIGH') ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.withOpacity(0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ankle-Safe',
                              style: TextStyle(
                                color: Colors.orange.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
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
}