import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'post_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final String workoutType;
  final int duration;
  final List<Map<String, dynamic>> exercises;

  const WorkoutScreen({
    Key? key,
    required this.workoutType,
    required this.duration,
    required this.exercises,
  }) : super(key: key);

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _entryController;
  late AnimationController _glowController;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _glow;
  late Animation<double> _pulse;

  // Workout state
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  int _secondsRemaining = 30; // Default exercise duration
  Timer? _timer;
  bool _isPaused = false;
  bool _isResting = false;
  int _totalSecondsElapsed = 0;

  // Progress tracking
  double get _overallProgress {
    return (_currentExerciseIndex + (_currentSet - 1) / _totalSets) / widget.exercises.length;
  }

  int get _totalSets {
    final exercise = widget.exercises[_currentExerciseIndex];
    return int.tryParse(exercise['sets']?.toString() ?? '1') ?? 1;
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _startExercise();
  }

  void _initAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _scaleIn = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    ));

    _glow = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _entryController.forward();
  }

  void _startExercise() {
    final exercise = widget.exercises[_currentExerciseIndex];
    if (exercise['duration'] != null) {
      // Parse duration (e.g., "2 min" -> 120 seconds)
      final durationStr = exercise['duration'] as String;
      final minutes = int.tryParse(durationStr.split(' ')[0]) ?? 1;
      _secondsRemaining = minutes * 60;
    } else {
      // For rep-based exercises, use 30 seconds per set
      _secondsRemaining = 30;
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _totalSecondsElapsed++;
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _onExerciseComplete();
          }
        });
      }
    });
  }

  void _onExerciseComplete() {
    HapticFeedback.mediumImpact();

    if (_isResting) {
      // Rest period complete, move to next set or exercise
      _isResting = false;
      if (_currentSet < _totalSets) {
        _currentSet++;
        _startExercise();
      } else {
        _nextExercise();
      }
    } else {
      // Exercise complete, start rest period
      if (_currentSet < _totalSets) {
        _isResting = true;
        _secondsRemaining = 15; // 15 second rest between sets
      } else {
        _nextExercise();
      }
    }
  }

  void _nextExercise() {
    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _isResting = false;
      });
      _startExercise();
    } else {
      _completeWorkout();
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _currentSet = 1;
        _isResting = false;
      });
      _startExercise();
    }
  }

  void _completeWorkout() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PostWorkoutScreen(
              workoutType: widget.workoutType,
              duration: _totalSecondsElapsed ~/ 60,
              exercises: widget.exercises,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryController.dispose();
    _glowController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = widget.exercises[_currentExerciseIndex];

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
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildProgressBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildVideoPlayer(),
                              const SizedBox(height: 30),
                              _buildExerciseInfo(currentExercise),
                              const SizedBox(height: 30),
                              _buildTimer(),
                              const SizedBox(height: 40),
                              _buildControls(),
                              const SizedBox(height: 40),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showExitDialog();
            },
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
            padding: EdgeInsets.zero,
          ),
          Text(
            'EXERCISE ${_currentExerciseIndex + 1} OF ${widget.exercises.length}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // Show workout settings/info
            },
            icon: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 24,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _overallProgress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return AnimatedBuilder(
      animation: _scaleIn,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleIn.value,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Video placeholder with diagonal lines
                  CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: _VideoPlaceholderPainter(),
                  ),
                  // Play button overlay
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white.withOpacity(0.8),
                      size: 32,
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

  Widget _buildExerciseInfo(Map<String, dynamic> exercise) {
    return Column(
      children: [
        Text(
          _isResting ? 'REST' : exercise['name'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (!_isResting && exercise['sets'] != null) ...[
          Text(
            'SET $_currentSet OF ${exercise['sets']}',
            style: TextStyle(
              color: const Color(0xFFD4AF37).withOpacity(0.8),
              fontSize: 16,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (!_isResting && exercise['reps'] != null)
          Text(
            exercise['reps'] + ' REPS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildTimer() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: _isResting ? _pulse.value : 1.0,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isResting
                    ? const Color(0xFFD4AF37).withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: _isResting ? [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ] : [],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_secondsRemaining),
                    style: TextStyle(
                      color: _isResting ? const Color(0xFFD4AF37) : Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 2,
                    ),
                  ),
                  if (_isResting)
                    Text(
                      'NEXT: ${widget.exercises[_currentExerciseIndex]['name']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        letterSpacing: 1,
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

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          Icons.skip_previous,
              () => _previousExercise(),
          enabled: _currentExerciseIndex > 0,
        ),
        const SizedBox(width: 24),
        AnimatedBuilder(
          animation: _glow,
          builder: (context, child) {
            return GestureDetector(
              onTap: _togglePause,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isPaused ? [
                      const Color(0xFFD4AF37),
                      const Color(0xFFB8941F),
                    ] : [
                      Colors.white,
                      const Color(0xFFE0E0E0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isPaused ? const Color(0xFFD4AF37) : Colors.white)
                          .withOpacity(0.3 * _glow.value),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.black,
                  size: 36,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 24),
        _buildControlButton(
          Icons.skip_next,
              () => _nextExercise(),
          enabled: _currentExerciseIndex < widget.exercises.length - 1,
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? () {
        HapticFeedback.lightImpact();
        onPressed();
      } : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(enabled ? 0.1 : 0.05),
          border: Border.all(
            color: Colors.white.withOpacity(enabled ? 0.2 : 0.1),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(enabled ? 0.8 : 0.3),
          size: 28,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: Text(
          'END WORKOUT?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Your progress will be saved',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CONTINUE',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeWorkout();
            },
            child: const Text(
              'END',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines
    const spacing = 20.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}