import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;

  // Stats data with separate loading states
  int _totalWorkouts = 0;
  double _totalHours = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  Map<String, int> _workoutsByType = {};
  Map<String, double> _weeklyProgress = {};
  List<Map<String, dynamic>> _recentWorkouts = [];
  Map<String, dynamic>? _userProfile;

  // Loading states for different sections
  bool _basicStatsLoaded = false;
  bool _weeklyDataLoaded = false;
  bool _distributionLoaded = false;
  bool _recentActivityLoaded = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadStatsIncrementally();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _loadStatsIncrementally() async {
    if (user == null) return;

    // Load in priority order
    _loadBasicStats();
    _loadWeeklyData();
    _loadDistributionData();
    _loadRecentActivity();
  }

  Future<void> _loadBasicStats() async {
    try {
      // First try cache
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get(const GetOptions(source: Source.cache));

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        setState(() {
          _totalWorkouts = data['total_workouts'] ?? 0;
          _totalHours = (data['total_minutes'] ?? 0) / 60.0;
          _currentStreak = data['cached_streak'] ?? 0;
          _longestStreak = data['longestStreak'] ?? 0;
          _userProfile = data;
          _basicStatsLoaded = true;
        });
      }

      // Then fetch fresh data
      final freshDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get(const GetOptions(source: Source.server));

      if (freshDoc.exists) {
        final data = freshDoc.data() ?? {};

        // Calculate current streak if not cached
        int currentStreak = data['cached_streak'] ?? 0;
        if (currentStreak == 0) {
          currentStreak = await _calculateCurrentStreak();
        }

        setState(() {
          _totalWorkouts = data['total_workouts'] ?? 0;
          _totalHours = (data['total_minutes'] ?? 0) / 60.0;
          _currentStreak = currentStreak;
          _longestStreak = math.max(data['longestStreak'] ?? 0, currentStreak);
          _userProfile = data;
          _basicStatsLoaded = true;
        });

        // Update cache if needed
        if (data['cached_streak'] != currentStreak) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .update({
            'cached_streak': currentStreak,
            'longestStreak': _longestStreak,
          }).catchError((e) => print('Cache update error: $e'));
        }
      }
    } catch (e) {
      print('Error loading basic stats: $e');
      setState(() {
        _basicStatsLoaded = true; // Show defaults
      });
    }
  }

  Future<void> _loadWeeklyData() async {
    try {
      final weeklyProgress = await _calculateWeeklyProgress();
      if (mounted) {
        setState(() {
          _weeklyProgress = weeklyProgress;
          _weeklyDataLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading weekly data: $e');
      setState(() {
        _weeklyDataLoaded = true;
      });
    }
  }

  Future<void> _loadDistributionData() async {
    try {
      // Get workout distribution with limit for speed
      final workoutsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('workouts')
          .limit(100) // Limit for performance
          .get();

      Map<String, int> workoutsByType = {
        'strength': 0,
        'warmup': 0,
        'cooldown': 0,
      };

      for (var doc in workoutsQuery.docs) {
        final type = doc.data()['type'] ?? 'strength';
        workoutsByType[type] = (workoutsByType[type] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _workoutsByType = workoutsByType;
          _distributionLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading distribution: $e');
      setState(() {
        _distributionLoaded = true;
      });
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      final recentQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('workouts')
          .orderBy('completedAt', descending: true)
          .limit(5)
          .get();

      final recentWorkouts = recentQuery.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      if (mounted) {
        setState(() {
          _recentWorkouts = recentWorkouts;
          _recentActivityLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading recent activity: $e');
      setState(() {
        _recentActivityLoaded = true;
      });
    }
  }

  Future<int> _calculateCurrentStreak() async {
    if (user == null) return 0;

    try {
      final now = DateTime.now();
      int streak = 0;

      // Optimized: Check only last 30 days
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
      print('Error calculating streak: $e');
      return 0;
    }
  }

  Future<Map<String, double>> _calculateWeeklyProgress() async {
    if (user == null) return {};

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    Map<String, double> weeklyData = {};

    // Batch query for the entire week
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final weekWorkouts = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('workouts')
        .where('completedAt', isGreaterThanOrEqualTo: startOfWeek)
        .where('completedAt', isLessThan: endOfWeek)
        .get();

    // Initialize all days with 0
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var day in dayNames) {
      weeklyData[day] = 0;
    }

    // Process workouts
    for (var doc in weekWorkouts.docs) {
      final data = doc.data();
      final completedAt = (data['completedAt'] as Timestamp).toDate();
      final dayIndex = completedAt.weekday - 1;
      final dayName = dayNames[dayIndex];
      weeklyData[dayName] = (weeklyData[dayName] ?? 0) + (data['duration'] ?? 0).toDouble();
    }

    return weeklyData;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeController.value,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildOverviewGrid(),
                    const SizedBox(height: 32),
                    _buildWeeklyChart(),
                    const SizedBox(height: 32),
                    _buildWorkoutDistribution(),
                    const SizedBox(height: 32),
                    _buildRecentActivity(),
                    const SizedBox(height: 32),
                    _buildPersonalRecords(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
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
          const Text(
            'YOUR STATS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid() {
    if (!_basicStatsLoaded) {
      return _buildLoadingGrid();
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Total Workouts',
          value: _totalWorkouts.toString(),
          icon: Icons.fitness_center,
          isPrimary: true,
        ),
        _buildStatCard(
          title: 'Hours Trained',
          value: _totalHours.toStringAsFixed(1),
          icon: Icons.timer,
        ),
        _buildStatCard(
          title: 'Current Streak',
          value: '$_currentStreak days',
          icon: Icons.local_fire_department,
        ),
        _buildStatCard(
          title: 'Longest Streak',
          value: '$_longestStreak days',
          icon: Icons.emoji_events,
        ),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: List.generate(4, (index) => _buildLoadingCard()),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    bool isPrimary = false,
  }) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPrimary
                  ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                  : [const Color(0xFF0F0F0F), const Color(0xFF0A0A0A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFFD4AF37).withOpacity(0.5)
                  : const Color(0xFFD4AF37).withOpacity(0.2),
              width: isPrimary ? 1.5 : 1,
            ),
            boxShadow: isPrimary
                ? [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.2 * _glowController.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ]
                : [],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFFD4AF37),
                      size: 20,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isPrimary ? 28 : 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart() {
    if (!_weeklyDataLoaded) {
      return _buildLoadingChart();
    }

    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'This Week',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_weeklyProgress.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0)} min',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: (_weeklyProgress.values.isEmpty ? 60 : _weeklyProgress.values.reduce(math.max) * 1.2),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(
                          days[value.toInt()],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 30,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final value = _weeklyProgress[days[index]] ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFFB8941F),
                            Color(0xFFD4AF37),
                          ],
                        ),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutDistribution() {
    if (!_distributionLoaded) {
      return _buildLoadingChart();
    }

    final total = _workoutsByType.values.fold(0, (a, b) => a + b);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (total > 0)
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFFD4AF37),
                          value: (_workoutsByType['strength'] ?? 0).toDouble(),
                          title: '',
                          radius: 30,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFB8941F),
                          value: (_workoutsByType['warmup'] ?? 0).toDouble(),
                          title: '',
                          radius: 30,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFF8B6914),
                          value: (_workoutsByType['cooldown'] ?? 0).toDouble(),
                          title: '',
                          radius: 30,
                        ),
                      ],
                    ),
                  ),
                Text(
                  total.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Legend
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem('Strength', _workoutsByType['strength'] ?? 0, const Color(0xFFD4AF37), total),
                const SizedBox(height: 16),
                _buildLegendItem('Warm Up', _workoutsByType['warmup'] ?? 0, const Color(0xFFB8941F), total),
                const SizedBox(height: 16),
                _buildLegendItem('Cool Down', _workoutsByType['cooldown'] ?? 0, const Color(0xFF8B6914), total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color, int total) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        Text(
          '$count ($percentage%)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        if (!_recentActivityLoaded)
          _buildLoadingActivity()
        else if (_recentWorkouts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Text(
                'No workouts yet. Start your fitness journey!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...List.generate(
            math.min(_recentWorkouts.length, 5),
                (index) => _buildActivityItem(_recentWorkouts[index]),
          ),
      ],
    );
  }

  Widget _buildLoadingActivity() {
    return Column(
      children: List.generate(
        3,
            (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 180,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> workout) {
    final type = workout['type'] ?? 'strength';
    final duration = workout['duration'] ?? 0;
    final completedAt = (workout['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final exercises = workout['totalExercisesCompleted'] ?? 0;

    final typeIcons = {
      'strength': Icons.fitness_center,
      'warmup': Icons.wb_sunny_outlined,
      'cooldown': Icons.ac_unit,
    };

    final typeNames = {
      'strength': 'Strength Training',
      'warmup': 'Warm Up',
      'cooldown': 'Cool Down',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              typeIcons[type] ?? Icons.fitness_center,
              color: const Color(0xFFD4AF37),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeNames[type] ?? 'Workout',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(completedAt)} • $duration min • $exercises exercises',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalRecords() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFD4AF37),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRecordRow('Longest Workout', '${(_userProfile?['longestWorkout'] ?? 0)} min'),
          const SizedBox(height: 16),
          _buildRecordRow('Most Exercises', '${(_userProfile?['mostExercises'] ?? 0)} exercises'),
          const SizedBox(height: 16),
          _buildRecordRow('Perfect Week', '${(_userProfile?['perfectWeeks'] ?? 0)} weeks'),
        ],
      ),
    );
  }

  Widget _buildRecordRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD4AF37),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}