import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    // Entry animations
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800), // Slightly slower
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                'JD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainWorkout() {
    final isSelected = _selectedWorkout == 'strength';

    return GestureDetector(
      onTap: () => _onWorkoutSelected('strength'),
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
                color: Colors.white.withOpacity(isSelected ? 0.8 : 0.15),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
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
              ] : [],
            ),
            child: Center(
              child: Text(
                'STRENGTH',
                style: TextStyle(
                  color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7),
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecondaryWorkouts() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSecondaryOption('WARM UP', Icons.wb_sunny_outlined, 'warmup'),
        const SizedBox(width: 60),
        _buildSecondaryOption('COOL DOWN', Icons.ac_unit, 'cooldown'),
      ],
    );
  }

  Widget _buildSecondaryOption(String title, IconData icon, String id) {
    final isSelected = _selectedWorkout == id;

    return GestureDetector(
      onTap: () => _onWorkoutSelected(id),
      child: AnimatedBuilder(
        animation: _glowFade,
        builder: (context, child) {
          return Column(
            children: [
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0A0A0A),
                  border: Border.all(
                    color: Colors.white.withOpacity(isSelected ? 0.7 : 0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? [
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
                  color: Colors.white.withOpacity(isSelected ? 0.8 : 0.4),
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(isSelected ? 0.9 : 0.6),
                  fontSize: 14,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsOrButton() {
    return AnimatedBuilder(
      animation: _transform,
      builder: (context, child) {
        return Container(
          // Expand container significantly to prevent any glow cutoff
          constraints: const BoxConstraints(minHeight: 160),
          child: AnimatedCrossFade(
            firstChild: _buildStatsBox(),
            secondChild: Container(
              // More padding for the glow
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: _buildStartButton(),
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
              color: const Color(0xFFFFD700).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.1 * _statsGlow.value),
                blurRadius: 30,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.05 * _statsGlow.value),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildStatItem('7', 'DAY STREAK')),
                _buildDivider(),
                Expanded(child: _buildStatItem('4', 'THIS WEEK')),
                _buildDivider(),
                Expanded(child: _buildStatItem('156', 'TOTAL')),
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
      color: const Color(0xFFFFD700).withOpacity(0.2),
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          // Navigate to workout
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

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, true),
          _buildNavItem(Icons.calendar_today, false),
          _buildNavItem(Icons.trending_up, false),
          _buildNavItem(Icons.person, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
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