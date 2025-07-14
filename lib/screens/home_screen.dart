import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _LuxuriousHomeScreenState();
}

class _LuxuriousHomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedDuration = '15 min';

  // Animation controllers
  late final AnimationController _glowController;
  late final AnimationController _titleShimmerController;
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;

  late final Animation<double> _glowAnimation;
  late final Animation<double> _titleShimmerAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;

  // Workout data with luxury theme
  final List<Map<String, dynamic>> workouts = [
    {
      'title': 'Morning Ritual',
      'subtitle': 'Upper Body\nElegance & Power',
      'icon': '✨',
      'gradient': [const Color(0xFF2D1B69), const Color(0xFF11998E)],
      'glowColor': const Color(0xFF38EF7D),
      'accentColor': const Color(0xFF11998E),
      'description': 'Begin your day with intention',
    },
    {
      'title': 'Recovery Suite',
      'subtitle': 'Mobility &\nRestoration',
      'icon': '🌙',
      'gradient': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      'glowColor': const Color(0xFF8E2DE2),
      'accentColor': const Color(0xFF4A00E0),
      'description': 'Nurture your body\'s wisdom',
    },
    {
      'title': 'Elite Performance',
      'subtitle': 'High Intensity\nMastery',
      'icon': '⚡',
      'gradient': [const Color(0xFFFF6B6B), const Color(0xFF4ECDC4)],
      'glowColor': const Color(0xFF4ECDC4),
      'accentColor': const Color(0xFFFF6B6B),
      'description': 'Unleash your potential',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _titleShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Create animations
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8)
        .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _titleShimmerAnimation = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _titleShimmerController, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _titleShimmerController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildLuxuriousHeader(),
              _buildElegantWeekStreak(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: workouts.length,
                  itemBuilder: (_, i) => _buildLuxuriousWorkoutCard(workouts[i]),
                ),
              ),
              _buildPremiumBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuriousHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0A),
            const Color(0xFF0A0A0A).withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Streak indicator with luxury styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.2),
                  const Color(0xFFFFA500).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  '28',
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Elegant logo
          AnimatedBuilder(
            animation: _titleShimmerAnimation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment(_titleShimmerAnimation.value - 1, 0),
                    end: Alignment(_titleShimmerAnimation.value, 0),
                    colors: [
                      Colors.white.withOpacity(0.5),
                      Colors.white,
                      Colors.white.withOpacity(0.5),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(rect);
                },
                child: const Text(
                  'PEAKFIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 4,
                  ),
                ),
              );
            },
          ),

          // Profile avatar with glow
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(_glowAnimation.value * 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildElegantWeekStreak() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const currentDay = 3;
    const completedDays = [0, 1, 2];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(days.length, (idx) {
          final isToday = idx == currentDay;
          final isCompleted = completedDays.contains(idx);

          return AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isToday ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isCompleted
                        ? LinearGradient(
                      colors: [
                        const Color(0xFFFFD700),
                        const Color(0xFFFFA500),
                      ],
                    )
                        : isToday
                        ? LinearGradient(
                      colors: [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                      ],
                    )
                        : null,
                    color: !isCompleted && !isToday
                        ? Colors.white.withOpacity(0.05)
                        : null,
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFF6366F1).withOpacity(0.8)
                          : isCompleted
                          ? const Color(0xFFFFD700).withOpacity(0.8)
                          : Colors.white.withOpacity(0.1),
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: (isToday || isCompleted)
                        ? [
                      BoxShadow(
                        color: (isCompleted
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF6366F1))
                            .withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ]
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          days[idx],
                          style: TextStyle(
                            color: isCompleted || isToday
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            fontWeight: (isToday || isCompleted)
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                        if (isCompleted)
                          const Text(
                            '✨',
                            style: TextStyle(fontSize: 8),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildLuxuriousWorkoutCard(Map<String, dynamic> workout) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Elegant title with shimmer effect
          AnimatedBuilder(
            animation: _titleShimmerAnimation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment(_titleShimmerAnimation.value - 1, 0),
                    end: Alignment(_titleShimmerAnimation.value, 0),
                    colors: [
                      workout['glowColor'].withOpacity(0.3),
                      workout['glowColor'],
                      workout['glowColor'].withOpacity(0.3),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(rect);
                },
                child: Text(
                  workout['title'],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            workout['subtitle'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w200,
              color: Colors.white,
              height: 1.1,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            workout['description'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 20),

          // Icon and date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                workout['icon'],
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  'Jun 4',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          _buildPageIndicator(),

          const Spacer(),

          _buildLuxuriousStartButton(workout),

          const SizedBox(height: 30),

          _buildElegantDurationSelector(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(workouts.length, (idx) {
        final isActive = _currentPage == idx;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: isActive
                ? LinearGradient(
              colors: [
                workouts[_currentPage]['glowColor'],
                workouts[_currentPage]['accentColor'],
              ],
            )
                : null,
            color: !isActive ? Colors.white.withOpacity(0.2) : null,
            boxShadow: isActive
                ? [
              BoxShadow(
                color: workouts[_currentPage]['glowColor'].withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildLuxuriousStartButton(Map<String, dynamic> workout) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // TODO: Navigate to workout
          },
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: workout['glowColor'].withOpacity(_glowAnimation.value * 0.6),
                  blurRadius: 40 + (_glowAnimation.value * 20),
                  spreadRadius: 5 + (_glowAnimation.value * 10),
                ),
                BoxShadow(
                  color: workout['accentColor'].withOpacity(_glowAnimation.value * 0.3),
                  blurRadius: 60,
                  spreadRadius: 15,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'START',
                    style: TextStyle(
                      color: const Color(0xFF0A0A0A),
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 1,
                    color: const Color(0xFF0A0A0A).withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildElegantDurationSelector() {
    return GestureDetector(
      onTap: _showDurationPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedDuration,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.expand_more,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showDurationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        const options = ['5 min', '10 min', '15 min', '20 min', '30 min', '45 min'];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1A1A),
                const Color(0xFF0A0A0A),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Duration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
                ...options.map((duration) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedDuration = duration);
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.white.withOpacity(0.03),
                    trailing: _selectedDuration == duration
                        ? Icon(
                      Icons.check,
                      color: workouts[_currentPage]['glowColor'],
                    )
                        : null,
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0A).withOpacity(0.8),
            const Color(0xFF0A0A0A),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', true),
          _buildNavItem(Icons.emoji_events_outlined, 'Challenges', false),
          _buildNavItem(Icons.calendar_month_outlined, 'Calendar', false),
          _buildNavItem(Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isSelected
                ? LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.2),
                const Color(0xFF8B5CF6).withOpacity(0.1),
              ],
            )
                : null,
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.5),
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}