import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _statsGlowController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _statsGlowAnimation;

  String? _selectedOption;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _statsGlowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Setup animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _statsGlowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsGlowController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _statsGlowController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getDayString() {
    final now = DateTime.now();
    const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    const months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];

    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  void _selectWorkout(String option) {
    setState(() {
      _selectedOption = option;
    });

    // Reset and restart the glow animation for smooth fade-in every time
    _glowController.reset();
    _glowController.forward();

    HapticFeedback.mediumImpact();

    // Start workout after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      // Navigate to workout
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient layer 1
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.3, -0.5),
                radius: 1.5,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Background gradient layer 2
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.5, 0.8),
                radius: 1.2,
                colors: [
                  Colors.white.withOpacity(0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Glass morphism layer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.01),
                  Colors.white.withOpacity(0.005),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildMainContent(),
                  ),
                  _buildBottomSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getDayString(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getGreeting(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                'JD',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Today's Focus
          Text(
            "TODAY'S FOCUS",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w300,
            ),
          ),

          const SizedBox(height: 50),

          // Main workout circle
          GestureDetector(
            onTap: () => _selectWorkout('main'),
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                final isSelected = _selectedOption == 'main';
                return Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.6 * _glowAnimation.value)
                          : Colors.white.withOpacity(0.15),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15 * _glowAnimation.value),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.08 * _glowAnimation.value),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                    ] : [],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.03),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'STRENGTH',
                            style: TextStyle(
                              color: Colors.white.withOpacity(isSelected ? 1.0 : 0.9),
                              fontSize: 32,
                              fontWeight: FontWeight.w200,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 50,
                            height: 1,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 60),

          // Quick options
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickOption('WARM UP', Icons.wb_sunny_outlined, 'warmup'),
              const SizedBox(width: 60),
              _buildQuickOption('COOL DOWN', Icons.ac_unit_outlined, 'cooldown'),
            ],
          ),

          const SizedBox(height: 80),

          // Stats section
          _buildStatsSection(),
        ],
      ),
    );
  }

  Widget _buildQuickOption(String title, IconData icon, String id) {
    final isSelected = _selectedOption == id;

    return GestureDetector(
      onTap: () => _selectWorkout(id),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.5 * _glowAnimation.value)
                        : Colors.white.withOpacity(0.12),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.25 * _glowAnimation.value),
                      blurRadius: 15,
                      spreadRadius: -3,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1 * _glowAnimation.value),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ] : [],
                ),
                child: Icon(
                  icon,
                  color: Colors.white.withOpacity(isSelected ? 0.8 : 0.5),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(isSelected ? 0.9 : 0.7),
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsSection() {
    return AnimatedBuilder(
      animation: _statsGlowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGlowingStat('7', 'DAY STREAK', true),
              _buildDivider(),
              _buildGlowingStat('4', 'THIS WEEK', false),
              _buildDivider(),
              _buildGlowingStat('156', 'TOTAL', false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowingStat(String value, String label, bool highlight) {
    final glowColors = {
      'DAY STREAK': const Color(0xFFFFD700),
      'THIS WEEK': const Color(0xFF00D4FF),
      'TOTAL': const Color(0xFF9B51E0),
    };

    final glowColor = glowColors[label] ?? Colors.white;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.15 * _statsGlowAnimation.value),
                blurRadius: 25,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: glowColor.withOpacity(0.08 * _statsGlowAnimation.value),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Color.lerp(Colors.white, glowColor, 0.2),
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  shadows: [
                    Shadow(
                      color: glowColor.withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              if (highlight) ...[
                const SizedBox(width: 6),
                Text(
                  '🔥',
                  style: TextStyle(
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: Colors.orange.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.08),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, true),
          _buildNavItem(Icons.calendar_today_rounded, false),
          _buildNavItem(Icons.bar_chart_rounded, false),
          _buildNavItem(Icons.person_outline_rounded, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.white.withOpacity(0.08) : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.25),
          size: 24,
        ),
      ),
    );
  }
}