import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'time_selection_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _entryController;
  late AnimationController _glowController;
  late AnimationController _statsGlowController;
  late AnimationController _transformController;
  late AnimationController _backButtonController;

  // Animations
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _glowFade;
  late Animation<double> _statsGlow;
  late Animation<double> _transform;
  late Animation<double> _backButtonFade;

  String? _selectedWorkout;

  // User data
  final user = FirebaseAuth.instance.currentUser;
  String? _profileImageUrl;
  String? _username;
  DateTime? _accountCreatedDate;

  // Stats data with caching
  int _currentStreak = 0;
  int _weeklyWorkouts = 0;
  int _totalWorkouts = 0;
  bool _statsLoaded = false;
  DateTime? _lastStatsUpdate;

  // Stream subscription for real-time updates
  Stream<DocumentSnapshot>? _userStatsStream;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _loadUserData();
    _initializeStatsStream();
    _loadCachedStats();
  }

  // Initialize real-time stats stream
  void _initializeStatsStream() {
    if (user == null) return;

    _userStatsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots();

    // Listen to user document changes
    _userStatsStream?.listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            _totalWorkouts = data?['total_workouts'] ?? 0;
            _currentStreak = data?['cached_streak'] ?? _currentStreak;
            _weeklyWorkouts = data?['cached_weekly_workouts'] ?? _weeklyWorkouts;
            _profileImageUrl = data?['profileImageUrl'];
            _username = data?['username'];
            if (data?['createdAt'] != null) {
              _accountCreatedDate = (data!['createdAt'] as Timestamp).toDate();
            }
          });
        }
      }
    });
  }

  // Load cached stats immediately
  Future<void> _loadCachedStats() async {
    if (user == null) return;

    try {
      // First, get cached stats from user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get(const GetOptions(source: Source.cache));

      if (userDoc.exists) {
        setState(() {
          _totalWorkouts = userDoc.data()?['total_workouts'] ?? 0;
          _currentStreak = userDoc.data()?['cached_streak'] ?? 0;
          _weeklyWorkouts = userDoc.data()?['cached_weekly_workouts'] ?? 0;
          _profileImageUrl = userDoc.data()?['profileImageUrl'];
          _username = userDoc.data()?['username'];
          if (userDoc.data()?['createdAt'] != null) {
            _accountCreatedDate = (userDoc.data()!['createdAt'] as Timestamp).toDate();
          }
          _statsLoaded = true;
        });
      }

      // Then fetch fresh data from server if needed
      final serverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get(const GetOptions(source: Source.server));

      if (serverDoc.exists && mounted) {
        final data = serverDoc.data() ?? {};

        // Check if cached values are recent (within last hour)
        final lastUpdate = data['last_stats_update'] as Timestamp?;
        final needsUpdate = lastUpdate == null ||
            DateTime.now().difference(lastUpdate.toDate()).inHours > 1;

        setState(() {
          _totalWorkouts = data['total_workouts'] ?? 0;
          _currentStreak = data['cached_streak'] ?? 0;
          _weeklyWorkouts = data['cached_weekly_workouts'] ?? 0;
          _profileImageUrl = data['profileImageUrl'];
          _username = data['username'];
          if (data['createdAt'] != null) {
            _accountCreatedDate = (data['createdAt'] as Timestamp).toDate();
          }
          _statsLoaded = true;
        });

        // Update if needed in background
        if (needsUpdate) {
          _updateLightweightStats();
        }
      }
    } catch (e) {
      // If cache fails, load fresh
      _loadFreshStats();
    }
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get(const GetOptions(source: Source.cache));

      if (doc.exists && mounted) {
        setState(() {
          _profileImageUrl = doc.data()?['profileImageUrl'];
          _username = doc.data()?['username'];
          if (doc.data()?['createdAt'] != null) {
            _accountCreatedDate = (doc.data()!['createdAt'] as Timestamp).toDate();
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Lightweight stats update (only when really needed)
  Future<void> _updateLightweightStats() async {
    if (user == null) return;

    try {
      // First check if we need to update at all
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data() ?? {};
      final lastUpdate = data['last_stats_update'] as Timestamp?;

      // Skip if updated within last 5 minutes
      if (lastUpdate != null &&
          DateTime.now().difference(lastUpdate.toDate()).inMinutes < 5) {
        // Just use cached values
        if (mounted) {
          setState(() {
            _currentStreak = data['cached_streak'] ?? 0;
            _weeklyWorkouts = data['cached_weekly_workouts'] ?? 0;
          });
        }
        return;
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Check only today for streak continuation
      final todayWorkouts = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('workouts')
          .where('completedAt', isGreaterThanOrEqualTo: todayStart)
          .where('completedAt', isLessThan: todayStart.add(const Duration(days: 1)))
          .limit(1)
          .get();

      // Quick streak check - if no workout today and cached streak > 0,
      // we might have broken the streak
      int streak = data['cached_streak'] ?? 0;
      if (todayWorkouts.docs.isEmpty && streak > 0) {
        // Check yesterday
        final yesterday = todayStart.subtract(const Duration(days: 1));
        final yesterdayWorkouts = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('workouts')
            .where('completedAt', isGreaterThanOrEqualTo: yesterday)
            .where('completedAt', isLessThan: todayStart)
            .limit(1)
            .get();

        if (yesterdayWorkouts.docs.isEmpty) {
          streak = 0; // Streak is broken
        }
      }

      // For weekly workouts, just count this week
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final weekWorkouts = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('workouts')
          .where('completedAt', isGreaterThanOrEqualTo: startOfWeek)
          .get();

      final weekCount = weekWorkouts.docs.length;

      if (mounted) {
        setState(() {
          _weeklyWorkouts = weekCount;
          _currentStreak = streak;
        });

        // Update cache in Firestore
        FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'cached_streak': streak,
          'cached_weekly_workouts': weekCount,
          'last_stats_update': FieldValue.serverTimestamp(),
        }).catchError((e) => print('Cache update error: $e'));
      }
    } catch (e) {
      print('Error updating lightweight stats: $e');
    }
  }

  // Quick streak calculation (last 7 days only for speed)
  Future<int> _calculateQuickStreak() async {
    if (user == null) return 0;

    try {
      final now = DateTime.now();
      int streak = 0;
      bool streakBroken = false;

      // Only check last 7 days for quick calculation
      for (int i = 0; i < 7 && !streakBroken; i++) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final workouts = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('workouts')
            .where('completedAt', isGreaterThanOrEqualTo: startOfDay)
            .where('completedAt', isLessThan: endOfDay)
            .limit(1)
            .get();

        if (workouts.docs.isNotEmpty) {
          streak++;
        } else if (i > 0) {
          streakBroken = true;
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating quick streak: $e');
      return _currentStreak; // Return cached value on error
    }
  }

  Future<void> _loadFreshStats() async {
    if (user == null) return;

    // Avoid too frequent updates
    if (_lastStatsUpdate != null &&
        DateTime.now().difference(_lastStatsUpdate!).inSeconds < 30) {
      return;
    }

    try {
      _lastStatsUpdate = DateTime.now();

      // Load user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        _totalWorkouts = userDoc.data()?['total_workouts'] ?? 0;
        if (userDoc.data()?['createdAt'] != null) {
          _accountCreatedDate = (userDoc.data()!['createdAt'] as Timestamp).toDate();
        }
      }

      // Calculate current streak and weekly workouts in parallel
      final results = await Future.wait([
        _calculateFullStreak(),
        _calculateWeeklyWorkouts(),
      ]);

      _currentStreak = results[0] as int;
      _weeklyWorkouts = results[1] as int;

      if (mounted) {
        setState(() {
          _statsLoaded = true;
        });

        // Update cache
        FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'cached_streak': _currentStreak,
          'cached_weekly_workouts': _weeklyWorkouts,
          'last_stats_update': FieldValue.serverTimestamp(),
        }).catchError((e) => print('Cache update error: $e'));
      }
    } catch (e) {
      print('Error loading fresh stats: $e');
      setState(() {
        _statsLoaded = true; // Show whatever we have
      });
    }
  }

  Future<int> _calculateFullStreak() async {
    if (user == null) return 0;

    try {
      final now = DateTime.now();
      int streak = 0;

      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final workouts = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('workouts')
            .where('completedAt', isGreaterThanOrEqualTo: startOfDay)
            .where('completedAt', isLessThan: endOfDay)
            .limit(1)
            .get();

        if (workouts.docs.isNotEmpty) {
          if (i == 0 || streak > 0) {
            streak++;
          }
        } else if (i > 0 && streak > 0) {
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating full streak: $e');
      return 0;
    }
  }

  Future<int> _calculateWeeklyWorkouts() async {
    if (user == null) return 0;

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final workouts = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('workouts')
          .where('completedAt', isGreaterThanOrEqualTo: startOfWeek)
          .get();

      return workouts.docs.length;
    } catch (e) {
      print('Error calculating weekly workouts: $e');
      return 0;
    }
  }

  void _resetToDefaultState() {
    // Reset selection state
    setState(() {
      _selectedWorkout = null;
    });
    _glowController.reset();
    _transformController.reset();
    _backButtonController.reset();
  }

  void _initAnimations() {
    // Entry animations
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _statsGlowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _transformController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _backButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Define animations
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

    _glowFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _statsGlow = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsGlowController,
      curve: Curves.easeInOut,
    ));

    _transform = CurvedAnimation(
      parent: _transformController,
      curve: Curves.easeInOutCubic,
    );

    _backButtonFade = CurvedAnimation(
      parent: _backButtonController,
      curve: Curves.easeOut,
    );
  }

  void _startAnimations() {
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _statsGlowController.dispose();
    _transformController.dispose();
    _backButtonController.dispose();
    super.dispose();
  }

  void _onWorkoutSelected(String workout) {
    if (_selectedWorkout != workout) {
      setState(() {
        _selectedWorkout = workout;
      });
      _glowController.reset();
      _glowController.forward();
      _transformController.forward();
      _backButtonController.forward();
      HapticFeedback.mediumImpact();
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedWorkout = null;
    });
    _glowController.reset();
    _transformController.reverse();
    _backButtonController.reverse();
    HapticFeedback.lightImpact();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Map<String, dynamic>? _getTodaysWorkout() {
    // Basketball-specific schedule matching the ScheduleScreen
    final basketballSchedule = {
      'Monday': {
        'title': 'EXPLOSIVE POWER',
        'focus': ['PLYOMETRICS', 'GLUTES', 'CORE'],
        'intensity': 'HIGH',
      },
      'Tuesday': {
        'title': 'POSTURE & STABILITY',
        'focus': ['UPPER BACK', 'SHOULDERS', 'BALANCE'],
        'intensity': 'MEDIUM',
      },
      'Wednesday': {
        'title': 'LOWER BODY STRENGTH',
        'focus': ['QUADS', 'HAMSTRINGS', 'CALVES'],
        'intensity': 'HIGH',
      },
      'Thursday': {
        'title': 'ACTIVE RECOVERY',
        'focus': ['MOBILITY', 'FLEXIBILITY', 'ANKLE REHAB'],
        'intensity': 'LOW',
      },
      'Friday': {
        'title': 'VERTICAL FOCUS',
        'focus': ['JUMP TECHNIQUE', 'EXPLOSIVENESS', 'CORE'],
        'intensity': 'HIGH',
      },
      'Saturday': {
        'title': 'BASKETBALL SKILLS',
        'focus': ['AGILITY', 'COORDINATION', 'ENDURANCE'],
        'intensity': 'MEDIUM',
      },
      'Sunday': {
        'title': 'REST & RECOVERY',
        'focus': ['RECOVERY', 'NUTRITION', 'MENTAL'],
        'intensity': 'REST',
      },
    };

    // First week schedule (Day 1-7)
    final firstWeekSchedule = {
      'Day 1': {
        'title': 'EXPLOSIVE POWER',
        'focus': ['PLYOMETRICS', 'GLUTES', 'CORE'],
        'intensity': 'HIGH',
      },
      'Day 2': {
        'title': 'POSTURE & STABILITY',
        'focus': ['UPPER BACK', 'SHOULDERS', 'BALANCE'],
        'intensity': 'MEDIUM',
      },
      'Day 3': {
        'title': 'LOWER BODY STRENGTH',
        'focus': ['QUADS', 'HAMSTRINGS', 'CALVES'],
        'intensity': 'HIGH',
      },
      'Day 4': {
        'title': 'ACTIVE RECOVERY',
        'focus': ['MOBILITY', 'FLEXIBILITY', 'ANKLE REHAB'],
        'intensity': 'LOW',
      },
      'Day 5': {
        'title': 'VERTICAL FOCUS',
        'focus': ['JUMP TECHNIQUE', 'EXPLOSIVENESS', 'CORE'],
        'intensity': 'HIGH',
      },
      'Day 6': {
        'title': 'BASKETBALL SKILLS',
        'focus': ['AGILITY', 'COORDINATION', 'ENDURANCE'],
        'intensity': 'MEDIUM',
      },
      'Day 7': {
        'title': 'REST & RECOVERY',
        'focus': ['RECOVERY', 'NUTRITION', 'MENTAL'],
        'intensity': 'REST',
      },
    };

    final now = DateTime.now();

    // Check if user is in first week (account created within last 7 days)
    if (_accountCreatedDate != null) {
      final daysSinceCreation = now.difference(_accountCreatedDate!).inDays;

      if (daysSinceCreation < 7) {
        // User is in first week - use Day 1-7 schedule
        final dayNumber = daysSinceCreation + 1;
        return firstWeekSchedule['Day $dayNumber'];
      }
    }

    // After first week, use standard Monday-Sunday schedule
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = days[now.weekday - 1];
    return basketballSchedule[today];
  }

  String _getDateString() {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];

    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          _buildBackground(),
          _buildContent(),
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

  Widget _buildContent() {
    return SafeArea(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildMainWorkout(),
                          const SizedBox(height: 35),
                          _buildSecondaryWorkouts(),
                          const SizedBox(height: 50),
                          _buildStatsOrButton(),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomNav(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Back button
              AnimatedBuilder(
                animation: _backButtonFade,
                builder: (context, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _selectedWorkout != null ? 40 : 0,
                    child: _selectedWorkout != null
                        ? FadeTransition(
                      opacity: _backButtonFade,
                      child: IconButton(
                        onPressed: _clearSelection,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    )
                        : const SizedBox.shrink(),
                  );
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDateString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) {
                // Reset state and reload data when returning
                _resetToDefaultState();
                _loadUserData();
              });
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: _profileImageUrl != null
                    ? Image.network(
                  _profileImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(),
                )
                    : _buildInitialsAvatar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainWorkout() {
    final todaysWorkout = _getTodaysWorkout();
    final workoutTitle = todaysWorkout?['title']?.split(' ').first ?? 'TRAINING';
    final fullTitle = todaysWorkout?['title'] ?? 'BASKETBALL TRAINING';
    final intensity = todaysWorkout?['intensity'] ?? 'MEDIUM';
    final isRest = intensity == 'REST';
    final isSelected = _selectedWorkout == 'main';

    return GestureDetector(
      onTap: isRest ? null : () => _onWorkoutSelected('main'),
      child: AnimatedBuilder(
        animation: _glowFade,
        builder: (context, child) {
          return Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A0A0A),
              border: Border.all(
                color: isRest
                    ? const Color(0xFFD4AF37).withOpacity(0.3)
                    : Colors.white.withOpacity(isSelected ? 0.8 : 0.15),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected && !isRest ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4 * _glowFade.value),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2 * _glowFade.value),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1 * _glowFade.value),
                  blurRadius: 100,
                  spreadRadius: 30,
                ),
              ] : isRest ? [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRest) ...[
                  Icon(
                    Icons.spa_outlined,
                    color: const Color(0xFFD4AF37).withOpacity(0.8),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  isRest ? 'REST DAY' : workoutTitle.toUpperCase(),
                  style: TextStyle(
                    color: isRest
                        ? const Color(0xFFD4AF37).withOpacity(0.9)
                        : Colors.white.withOpacity(isSelected ? 1.0 : 0.7),
                    fontSize: isRest ? 24 : 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 3,
                  ),
                ),
                if (todaysWorkout != null && !isRest) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'TODAY\'S FOCUS',
                      style: TextStyle(
                        color: const Color(0xFFD4AF37).withOpacity(0.9),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (isRest) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Recovery & Nutrition',
                    style: TextStyle(
                      color: const Color(0xFFD4AF37).withOpacity(0.6),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecondaryWorkouts() {
    final todaysWorkout = _getTodaysWorkout();
    final intensity = todaysWorkout?['intensity'] ?? 'MEDIUM';
    final isRest = intensity == 'REST';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSecondaryOption('WARM UP', Icons.wb_sunny_outlined, 'warmup', !isRest),
        const SizedBox(width: 60),
        _buildSecondaryOption('COOL DOWN', Icons.ac_unit, 'cooldown', !isRest),
      ],
    );
  }

  Widget _buildSecondaryOption(String title, IconData icon, String id, bool enabled) {
    final isSelected = _selectedWorkout == id;

    return GestureDetector(
      onTap: enabled ? () => _onWorkoutSelected(id) : null,
      child: AnimatedBuilder(
        animation: _glowFade,
        builder: (context, child) {
          return Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Column(
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0A0A0A),
                    border: Border.all(
                      color: Colors.white.withOpacity(isSelected && enabled ? 0.7 : 0.15),
                      width: isSelected && enabled ? 1.5 : 1,
                    ),
                    boxShadow: isSelected && enabled ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3 * _glowFade.value),
                        blurRadius: 25,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15 * _glowFade.value),
                        blurRadius: 50,
                        spreadRadius: 5,
                      ),
                    ] : [],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white.withOpacity(isSelected && enabled ? 0.8 : 0.4),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isSelected && enabled ? 0.9 : 0.6),
                    fontSize: 14,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOrButton() {
    final todaysWorkout = _getTodaysWorkout();
    final intensity = todaysWorkout?['intensity'] ?? 'MEDIUM';
    final isRest = intensity == 'REST';

    return AnimatedBuilder(
      animation: _transform,
      builder: (context, child) {
        return Container(
          constraints: const BoxConstraints(minHeight: 160),
          child: AnimatedCrossFade(
            firstChild: _buildStatsBox(),
            secondChild: Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: isRest ? _buildRestDayMessage() : _buildStartButton(),
            ),
            crossFadeState: _selectedWorkout == null
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 500),
            sizeCurve: Curves.easeInOut,
          ),
        );
      },
    );
  }

  Widget _buildRestDayMessage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.self_improvement,
              color: const Color(0xFFD4AF37).withOpacity(0.8),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              'Rest & Recover',
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Focus on nutrition and sleep today',
              style: TextStyle(
                color: const Color(0xFFD4AF37).withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBox() {
    return AnimatedBuilder(
      animation: _statsGlow,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF0F0F0F),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.1 * _statsGlow.value),
                blurRadius: 30,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.05 * _statsGlow.value),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildStatItem(_currentStreak.toString(), 'DAY STREAK')),
                _buildDivider(),
                Expanded(child: _buildStatItem(_weeklyWorkouts.toString(), 'THIS WEEK')),
                _buildDivider(),
                Expanded(child: _buildStatItem(_totalWorkouts.toString(), 'TOTAL')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w200,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        if (label != 'DAY STREAK') ...[
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'WORKOUTS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFFD4AF37).withOpacity(0.2),
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.heavyImpact();
          // Navigate to time selection screen
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  TimeSelectionScreen(workoutType: _selectedWorkout!),
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
          ).then((_) {
            // Reset state when returning from time selection
            _resetToDefaultState();
            // Don't call _updateLightweightStats() - the listener will update automatically
          });
        },
        child: Container(
          width: 200,
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
                blurRadius: 15,
                offset: const Offset(0, 0),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 0),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 50,
                offset: const Offset(0, 0),
                spreadRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'START',
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
  }

  Widget _buildInitialsAvatar() {
    String initials = 'U';
    if (_username != null && _username!.isNotEmpty) {
      initials = _username![0].toUpperCase();
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      initials = user!.email![0].toUpperCase();
    }

    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, true, 0),
          _buildNavItem(Icons.calendar_today, false, 1),
          _buildNavItem(Icons.bar_chart, false, 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _handleNavigation(index);
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

  void _handleNavigation(int index) async {
    switch (index) {
      case 0:
      // Already on home - just reload stats
        _updateLightweightStats();
        break;
      case 1:
      // Navigate to schedule screen
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScheduleScreen()),
        ).then((_) {
          // Reset state and reload stats when returning
          _resetToDefaultState();
          _updateLightweightStats();
        });
        break;
      case 2:
      // Navigate to stats screen
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatsScreen()),
        ).then((_) {
          // Reset state and reload stats when returning
          _resetToDefaultState();
          _updateLightweightStats();
        });
        break;
    }
  }
}