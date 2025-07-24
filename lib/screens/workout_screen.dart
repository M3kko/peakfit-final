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
  late AnimationController _checkmarkController;

  // Animations
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _glow;
  late Animation<double> _pulse;
  late Animation<double> _checkmarkScale;

  // Workout state
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  int _secondsRemaining = 30; // Default exercise duration
  Timer? _timer;
  bool _isPaused = false;
  bool _isResting = false;
  int _totalSecondsElapsed = 0;

  // Inactivity tracking
  Timer? _inactivityTimer;
  static const int _inactivityThreshold = 300; // 5 minutes in seconds

  // Progress tracking
  double get _overallProgress {
    return (_currentExerciseIndex + (_currentSet - 1) / _totalSets) / widget.exercises.length;
  }

  int get _totalSets {
    final exercise = widget.exercises[_currentExerciseIndex];
    return int.tryParse(exercise['sets']?.toString() ?? '1') ?? 1;
  }

  bool get _isRepBased {
    final exercise = widget.exercises[_currentExerciseIndex];
    return exercise['reps'] != null && !_isResting;
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _startExercise();
    _startInactivityTimer();
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

    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

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

    _checkmarkScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _entryController.forward();
  }

  void _startInactivityTimer() {
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!_isPaused) {
      _inactivityTimer = Timer(Duration(seconds: _inactivityThreshold), () {
        if (mounted && !_isPaused) {
          _showInactivityDialog();
        }
      });
    }
  }

  void _startExercise() {
    final exercise = widget.exercises[_currentExerciseIndex];

    if (_isResting) {
      _secondsRemaining = 15; // Rest period
      _startTimer();
    } else if (exercise['duration'] != null) {
      // Parse duration (e.g., "2 min" -> 120 seconds)
      final durationStr = exercise['duration'] as String;
      final minutes = int.tryParse(durationStr.split(' ')[0]) ?? 1;
      _secondsRemaining = minutes * 60;
      _startTimer();
    } else if (exercise['reps'] != null) {
      // Rep-based exercise - no timer but still track elapsed time
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPaused) {
          setState(() {
            _totalSecondsElapsed++;
          });
        }
      });
    }
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
            _onTimerComplete();
          }
        });
      }
    });
  }

  void _onTimerComplete() {
    HapticFeedback.mediumImpact();

    if (_isResting) {
      // Rest period complete, move to next set or exercise
      setState(() {
        _isResting = false;
      });
      if (_currentSet < _totalSets) {
        _currentSet++;
        _startExercise();
      } else {
        _nextExercise();
      }
    } else {
      // Time-based exercise complete
      _onExerciseComplete();
    }
  }

  void _onExerciseComplete() {
    // Check if we need to rest or move on
    if (_currentSet < _totalSets) {
      setState(() {
        _isResting = true;
      });
      _startExercise();
    } else {
      _nextExercise();
    }
  }

  void _onRepExerciseComplete() {
    HapticFeedback.heavyImpact();
    _resetInactivityTimer();
    _checkmarkController.forward().then((_) {
      _checkmarkController.reset();
      _onExerciseComplete();
    });
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

  void _completeWorkout() {
    _timer?.cancel();
    _inactivityTimer?.cancel();
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
    if (_isPaused) {
      _inactivityTimer?.cancel();
    } else {
      _resetInactivityTimer();
    }
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inactivityTimer?.cancel();
    _entryController.dispose();
    _glowController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    _checkmarkController.dispose();
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

    return GestureDetector(
      onTap: _resetInactivityTimer,
      onPanUpdate: (_) => _resetInactivityTimer(),
      child: Scaffold(
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
                                const SizedBox(height: 40),
                                _buildTimerOrReps(currentExercise),
                                const SizedBox(height: 50),
                                if (_isRepBased) _buildCheckmarkButton(),
                                const SizedBox(height: 50),
                                _buildWorkoutStats(),
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
            onPressed: _togglePause,
            icon: Icon(
              _isPaused ? Icons.play_arrow : Icons.pause,
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
        if (!_isResting && exercise['sets'] != null)
          Text(
            'SET $_currentSet OF ${exercise['sets']}',
            style: TextStyle(
              color: const Color(0xFFD4AF37).withOpacity(0.8),
              fontSize: 16,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }

  Widget _buildTimerOrReps(Map<String, dynamic> exercise) {
    return Container(
      height: 180, // Fixed height to prevent jumping
      child: Center(
        child: _isRepBased
            ? _buildRepsDisplay(exercise)
            : _buildTimer(),
      ),
    );
  }

  Widget _buildRepsDisplay(Map<String, dynamic> exercise) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          exercise['reps']?.toString() ?? '10',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w200,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'REPS',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w300,
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
                  if (_isResting && _currentExerciseIndex < widget.exercises.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'NEXT: ${widget.exercises[_currentSet < _totalSets ? _currentExerciseIndex : _currentExerciseIndex + 1]['name']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildCheckmarkButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glow, _checkmarkScale]),
      builder: (context, child) {
        return Transform.scale(
          scale: _checkmarkScale.value,
          child: GestureDetector(
            onTap: _onRepExerciseComplete,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2 * _glow.value),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1 * _glow.value),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ColorFilter.mode(
                    Colors.green.withOpacity(0.1),
                    BlendMode.overlay,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.withOpacity(0.3),
                          Colors.green.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.green[300],
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutStats() {
    final currentExercise = widget.exercises[_currentExerciseIndex];
    final isLastExercise = _currentExerciseIndex == widget.exercises.length - 1;
    final nextExercise = !isLastExercise ? widget.exercises[_currentExerciseIndex + 1] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          // Current workout progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.timer_outlined,
                value: _formatTime(_totalSecondsElapsed),
                label: 'ELAPSED',
                color: Colors.white,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              _buildStatItem(
                icon: Icons.fitness_center,
                value: '${_currentExerciseIndex + 1}/${widget.exercises.length}',
                label: 'EXERCISES',
                color: const Color(0xFFD4AF37),
              ),
              if (currentExercise['sets'] != null) ...[
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
                _buildStatItem(
                  icon: Icons.repeat,
                  value: '$_currentSet/${_totalSets}',
                  label: 'SETS',
                  color: Colors.white,
                ),
              ],
            ],
          ),

          // Next exercise preview
          if (!_isResting && nextExercise != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white.withOpacity(0.4),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UP NEXT',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextExercise['name'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (nextExercise['reps'] != null)
                    Text(
                      '${nextExercise['reps']} reps',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    )
                  else if (nextExercise['duration'] != null)
                    Text(
                      nextExercise['duration'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color.withOpacity(0.6),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.5),
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
  showDialog(
  context: context,
  barrierColor: Colors.black.withOpacity(0.8),
  builder: (context) => Dialog(
  backgroundColor: Colors.transparent,
  child: Container(
  decoration: BoxDecoration(
  color: Colors.white.withOpacity(0.05),
  borderRadius: BorderRadius.circular(24),
  border: Border.all(
  color: Colors.white.withOpacity(0.1),
  width: 1,
  ),
  ),
  child: ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: BackdropFilter(
  filter: ColorFilter.mode(
  Colors.white.withOpacity(0.1),
  BlendMode.overlay,
  ),
  child: Padding(
  padding: const EdgeInsets.all(32),
  child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  Container(
  width: 64,
  height: 64,
  decoration: BoxDecoration(
  shape: BoxShape.circle,
  color: Colors.red.withOpacity(0.1),
  border: Border.all(
  color: Colors.red.withOpacity(0.3),
  width: 2,
  ),
  ),
  child: Icon(
  Icons.warning_rounded,
  color: Colors.red[300],
  size: 32,
  ),
  ),
  const SizedBox(height: 24),
  Text(
  'EXIT WORKOUT?',
  style: TextStyle(
  color: Colors.white,
  fontSize: 24,
  fontWeight: FontWeight.w200,
  letterSpacing: 2,
  ),
  textAlign: TextAlign.center,
  ),
  const SizedBox(height: 16),
  Text(
  'Your progress will NOT be saved',
  style: TextStyle(
  color: Colors.white.withOpacity(0.9),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  ),
  textAlign: TextAlign.center,
  ),
  const SizedBox(height: 8),
  Text(
  'You must complete the entire workout\nfor it to count',
  style: TextStyle(
  color: Colors.white.withOpacity(0.6),
  fontSize: 14,
  height: 1.5,
  ),
  textAlign: TextAlign.center,
  ),
  const SizedBox(height: 32),
  Row(
  children: [
  Expanded(
  child: _buildDialogButton(
  'KEEP GOING',
  Colors.green,
  () => Navigator.pop(context),
  isPrimary: true,
  ),
  ),
  const SizedBox(width: 16),
  Expanded(
  child: _buildDialogButton(
  'EXIT',
  Colors.red,
  () {
  Navigator.of(context).popUntil((route) => route.isFirst);
  },
  ),
  ),
  ],
  ),
  ],
  ),
  ),
  ),
  ),
  ),
  ),
  );
}

void _showInactivityDialog() {
  setState(() {
    _isPaused = true;
  });

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8),
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  color: const Color(0xFFD4AF37),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'STILL HERE?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your workout has been paused',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap continue to keep going',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildDialogButton(
                'CONTINUE',
                Colors.white,
                    () {
                  Navigator.pop(context);
                  setState(() {
                    _isPaused = false;
                  });
                  _resetInactivityTimer();
                },
                isPrimary: true,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildDialogButton(
    String label,
    Color color,
    VoidCallback onTap, {
      bool isPrimary = false,
      bool isFullWidth = false,
    }) {
  final Widget button = GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: isPrimary ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ColorFilter.mode(
            color.withOpacity(0.1),
            BlendMode.overlay,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 14,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  return isFullWidth ? button : button;
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