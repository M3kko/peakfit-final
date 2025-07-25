import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'dart:math';

class PostWorkoutScreen extends StatefulWidget {
  final String workoutType;
  final int duration; // in minutes
  final int totalSecondsElapsed;
  final List<Map<String, dynamic>> exercises;
  final int totalExercisesCompleted;

  const PostWorkoutScreen({
    Key? key,
    required this.workoutType,
    required this.duration,
    required this.totalSecondsElapsed,
    required this.exercises,
    required this.totalExercisesCompleted,
  }) : super(key: key);

  @override
  State<PostWorkoutScreen> createState() => _PostWorkoutScreenState();
}

class _PostWorkoutScreenState extends State<PostWorkoutScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _entryController;
  late AnimationController _confettiController;
  late AnimationController _glowController;
  late AnimationController _ratingController;

  // Animations
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _slideUp;
  late Animation<double> _confetti;
  late Animation<double> _glow;
  late Animation<double> _ratingScale;

  // Exercise ratings
  final Map<int, int> _exerciseRatings = {};
  int _currentRatingIndex = 0;
  bool _showingSummary = false;
  bool _canGoBack = true;
  bool _isSavingToFirebase = false;

  // Calculated stats
  late int _caloriesBurned;
  late int _avgHeartRate;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _calculateStats();
  }

  void _calculateStats() {
    // Calculate calories based on duration and workout intensity
    // Rough estimate: 8-12 calories per minute depending on workout type
    final caloriesPerMinute = widget.workoutType.toLowerCase().contains('intense') ||
        widget.workoutType.toLowerCase().contains('hiit')
        ? 12
        : widget.workoutType.toLowerCase().contains('strength')
        ? 10
        : 8;
    _caloriesBurned = (widget.duration * caloriesPerMinute).round();

    // Calculate average heart rate based on workout type
    // This is a rough estimate for demonstration
    _avgHeartRate = widget.workoutType.toLowerCase().contains('intense') ||
        widget.workoutType.toLowerCase().contains('hiit')
        ? 142
        : widget.workoutType.toLowerCase().contains('strength')
        ? 125
        : 115;
  }

  void _initAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _ratingController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _scaleIn = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    ));

    _slideUp = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    _confetti = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );

    _glow = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _ratingScale = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _ratingController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() {
    _entryController.forward();
    _confettiController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _ratingController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _confettiController.dispose();
    _glowController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  void _submitRating(int rating) {
    HapticFeedback.lightImpact();
    setState(() {
      _exerciseRatings[_currentRatingIndex] = rating;
    });

    // Animate to next exercise or show summary
    _ratingController.reverse().then((_) {
      if (_currentRatingIndex < widget.exercises.length - 1) {
        setState(() {
          _currentRatingIndex++;
        });
        _ratingController.forward();
      } else {
        // Final rating submitted, can't go back anymore
        setState(() {
          _canGoBack = false;
          _showingSummary = true;
        });
        _saveWorkoutToFirebase();
      }
    });
  }

  void _goToPreviousRating() {
    if (!_canGoBack || _currentRatingIndex == 0) return;

    HapticFeedback.lightImpact();
    _ratingController.reverse().then((_) {
      setState(() {
        _currentRatingIndex--;
      });
      _ratingController.forward();
    });
  }

  Future<void> _saveWorkoutToFirebase() async {
    if (_isSavingToFirebase) return;

    setState(() {
      _isSavingToFirebase = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Calculate average difficulty
      double averageDifficulty = 0;
      if (_exerciseRatings.isNotEmpty) {
        int totalRating = _exerciseRatings.values.reduce((a, b) => a + b);
        averageDifficulty = totalRating / _exerciseRatings.length;
      }

      // Prepare workout data for the main workout document
      final workoutData = {
        'userId': user.uid,
        'workoutType': widget.workoutType,
        'duration': widget.duration,
        'totalSecondsElapsed': widget.totalSecondsElapsed,
        'averageDifficulty': averageDifficulty,
        'totalExercisesCompleted': widget.totalExercisesCompleted,
        'completedAt': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
      };

      // Save main workout document
      final workoutRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .add(workoutData);

      // Save each exercise as a separate document in exercise_history
      for (int i = 0; i < widget.exercises.length; i++) {
        final exercise = widget.exercises[i];
        final exerciseData = {
          'userId': user.uid,
          'workoutId': workoutRef.id,
          'name': exercise['name'],
          'sets': exercise['sets'],
          'reps': exercise['reps'],
          'duration': exercise['duration'],
          'difficulty_rating': _exerciseRatings[i] ?? 3,
          'completedAt': FieldValue.serverTimestamp(),
          'date': DateTime.now().toIso8601String().split('T')[0],
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('exercise_history')
            .add(exerciseData);
      }

      // Update user stats
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final currentStats = userDoc.data() ?? {};
        final totalWorkouts = (currentStats['total_workouts'] ?? 0) + 1;
        final totalMinutes = (currentStats['total_minutes'] ?? 0) + widget.duration;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'total_workouts': totalWorkouts,
          'total_minutes': totalMinutes,
          'last_workout_date': FieldValue.serverTimestamp(),
        });
      }

      // Save workout stats for historical tracking
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workout_stats')
          .doc(workoutRef.id)
          .set({
        'workoutId': workoutRef.id,
        'duration': widget.duration,
        'totalSecondsElapsed': widget.totalSecondsElapsed,
        'averageDifficulty': averageDifficulty,
        'totalExercisesCompleted': widget.totalExercisesCompleted,
        'workoutType': widget.workoutType,
        'completedAt': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

    } catch (e) {
      print('Error saving workout: $e');
    } finally {
      setState(() {
        _isSavingToFirebase = false;
      });
    }
  }

  Color _getDifficultyColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  String _getDifficultyText(int rating) {
    switch (rating) {
      case 1:
        return 'Too Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Just Right';
      case 4:
        return 'Challenging';
      case 5:
        return 'Too Hard';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          _buildBackground(),
          // Confetti effect
          AnimatedBuilder(
            animation: _confetti,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(_confetti.value),
              );
            },
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeIn,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: _showingSummary
                      ? _buildSummary()
                      : _buildRatingView(),
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

  Widget _buildRatingView() {
    final currentExercise = widget.exercises[_currentRatingIndex];

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _scaleIn,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleIn.value,
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: const Color(0xFFD4AF37),
                            size: 80,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'GREAT WORK!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w200,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 60),
                AnimatedBuilder(
                  animation: _ratingScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _ratingScale.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideUp.value),
                        child: Column(
                          children: [
                            Text(
                              'How was',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentExercise['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            _buildRatingButtons(),
                            const SizedBox(height: 24),
                            _buildRatingLegend(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildNavigationButtons(),
                const SizedBox(height: 20),
                _buildProgressIndicator(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!_showingSummary)
            TextButton(
              onPressed: () {
                setState(() {
                  _showingSummary = true;
                });
                _saveWorkoutToFirebase();
              },
              child: Text(
                'SKIP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = _exerciseRatings[_currentRatingIndex] == rating;

        return GestureDetector(
          onTap: () => _submitRating(rating),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? _getDifficultyColor(rating).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: isSelected
                    ? _getDifficultyColor(rating)
                    : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: _getDifficultyColor(rating).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ] : [],
            ),
            child: Center(
              child: Text(
                rating.toString(),
                style: TextStyle(
                  color: isSelected
                      ? _getDifficultyColor(rating)
                      : Colors.white.withOpacity(0.6),
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRatingLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildLegendItem(1, 'Too Easy', Colors.green),
          const SizedBox(height: 16),
          _buildLegendItem(2, 'Easy', Colors.lightGreen),
          const SizedBox(height: 16),
          _buildLegendItem(3, 'Just Right', Colors.yellow),
          const SizedBox(height: 16),
          _buildLegendItem(4, 'Challenging', Colors.orange),
          const SizedBox(height: 16),
          _buildLegendItem(5, 'Too Hard', Colors.red),
        ],
      ),
    );
  }

  Widget _buildLegendItem(int rating, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$rating',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_canGoBack && _currentRatingIndex > 0)
          IconButton(
            onPressed: _goToPreviousRating,
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.exercises.length, (index) {
        final isCompleted = index <= _currentRatingIndex;
        final isCurrent = index == _currentRatingIndex;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isCompleted
                ? Colors.white.withOpacity(0.8)
                : Colors.white.withOpacity(0.2),
          ),
        );
      }),
    );
  }

  Widget _buildSummary() {
    // Calculate average difficulty
    double averageDifficulty = 0;
    if (_exerciseRatings.isNotEmpty) {
      int totalRating = _exerciseRatings.values.reduce((a, b) => a + b);
      averageDifficulty = totalRating / _exerciseRatings.length;
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _scaleIn,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleIn.value,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFD4AF37),
                                  const Color(0xFFB8941F),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'WORKOUT COMPLETE!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w200,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${widget.duration} minutes',
                            style: TextStyle(
                              color: const Color(0xFFD4AF37).withOpacity(0.8),
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                _buildStatsGrid(averageDifficulty),
                const SizedBox(height: 40),
                _buildExerciseSummary(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildStatsGrid(double averageDifficulty) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatWidget(
                icon: Icons.timer,
                value: '${widget.duration}',
                label: 'MINUTES',
                color: const Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatWidget(
                icon: Icons.fitness_center,
                value: widget.totalExercisesCompleted.toString(),
                label: 'EXERCISES',
                color: const Color(0xFFD4AF37),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatWidget(
          icon: Icons.speed,
          value: averageDifficulty > 0 ? averageDifficulty.toStringAsFixed(1) : '—',
          label: 'AVERAGE DIFFICULTY',
          color: const Color(0xFFD4AF37),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatWidget({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isFullWidth = false,
  }) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05 * _glow.value),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color.withOpacity(0.7),
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFD4AF37).withOpacity(0.7),
          size: 28,
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w200,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXERCISE FEEDBACK',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        ...widget.exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          final rating = _exerciseRatings[index] ?? 3;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDifficultyText(rating),
                        style: TextStyle(
                          color: _getDifficultyColor(rating).withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      Icons.circle,
                      size: 8,
                      color: i < rating
                          ? _getDifficultyColor(rating)
                          : Colors.white.withOpacity(0.2),
                    );
                  }),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
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
      child: _buildPrimaryButton(
        'DONE',
            () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  Widget _buildSecondaryButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onTap) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
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
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Random random = Random();

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint();
    final colors = [
      const Color(0xFFD4AF37),
      Colors.white,
      const Color(0xFFFFD700),
      Colors.orange,
    ];

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final startY = -50.0;
      final endY = size.height + 50;
      final y = startY + (endY - startY) * progress * (0.5 + random.nextDouble() * 0.5);

      final opacity = (1 - progress) * 0.8;
      paint.color = colors[i % colors.length].withOpacity(opacity);

      final particleSize = 2 + random.nextDouble() * 4;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 4 * math.pi * random.nextDouble());

      if (i % 3 == 0) {
        // Draw circles
        canvas.drawCircle(Offset.zero, particleSize.toDouble(), paint);
      } else if (i % 3 == 1) {
        // Draw rectangles
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particleSize * 2,
            height: particleSize.toDouble(),
          ),
          paint,
        );
      } else {
        // Draw triangles
        final path = Path()
          ..moveTo(0, -particleSize.toDouble())
          ..lineTo(particleSize.toDouble(), particleSize.toDouble())
          ..lineTo(-particleSize.toDouble(), particleSize.toDouble())
          ..close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}