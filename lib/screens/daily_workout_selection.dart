import 'package:flutter/material.dart';

class WorkoutPages extends StatefulWidget {
  const WorkoutPages({Key? key}) : super(key: key);

  @override
  State<WorkoutPages> createState() => _WorkoutPagesState();
}

class _WorkoutPagesState extends State<WorkoutPages>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedDuration = '15 min';

  // ──────────────────────────────────────────────
  //   Animation: button glow + title shimmer
  // ──────────────────────────────────────────────
  late final AnimationController _glowCtrl;
  late final Animation<double>       _glowAnim;

  late final AnimationController _titleGlowCtrl;
  late final Animation<double>       _titleGlowAnim;

  // ──────────────────────────────────────────────
  //   Workout cards
  // ──────────────────────────────────────────────
  final List<Map<String, dynamic>> workouts = [
    {
      'title': 'Already worked out today?',
      'subtitle': 'Upper Body\nMobility & strength',
      'icon': '🏃',
      'gradient': [const Color(0xFF6FCF97), const Color(0xFF27AE60)],
      'glowColor': const Color(0xFF6FCF97),
      'darkGlow':  const Color(0xFF27AE60),
      'lightGlow': const Color(0xFF90EE90),
    },
    {
      'title': 'Sore?',
      'subtitle': 'Upper Body\n& Active Recovery',
      'icon': '🧘',
      'gradient': [const Color(0xFF9B51E0), const Color(0xFF6B46C1)],
      'glowColor': const Color(0xFF9B51E0),
      'darkGlow':  const Color(0xFF6B46C1),
      'lightGlow': const Color(0xFFDDA0DD),
    },
    {
      'title': 'Ready for anything?',
      'subtitle': 'High Intensity\nUpper Body',
      'icon': '💪',
      'gradient': [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
      'glowColor': const Color(0xFF56CCF2),
      'darkGlow':  const Color(0xFF2F80ED),
      'lightGlow': const Color(0xFF87CEEB),
    },
  ];

  // ──────────────────────────────────────────────
  //   init / dispose
  // ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _glowCtrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 0.7)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _titleGlowCtrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _titleGlowAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _titleGlowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _titleGlowCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  //   build
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWeekDays(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: workouts.length,
                itemBuilder: (_, i) => _buildWorkoutPage(workouts[i]),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //   header
  // ──────────────────────────────────────────────
  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: const [
          Text('🔥', style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Text('28', style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        const Text('PeakFit',
            style:
            TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(width: 60),
      ],
    ),
  );

  // ──────────────────────────────────────────────
  //   weekday streak
  // ──────────────────────────────────────────────
  Widget _buildWeekDays() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const currentDay = 3;
    const completedDays = [0, 1, 2];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(days.length, (idx) {
          final isToday = idx == currentDay;
          final done = completedDays.contains(idx);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? Colors.orange.withOpacity(0.2)
                  : (isToday ? Colors.white : Colors.grey.shade800),
              border: isToday
                  ? Border.all(color: Colors.white, width: 2)
                  : (done
                  ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1)
                  : null),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (done) const SizedBox(height: 2),
                  Text(
                    days[idx],
                    style: TextStyle(
                      color: done
                          ? Colors.orange
                          : (isToday ? Colors.black : Colors.grey.shade400),
                      fontWeight: (isToday || done) ? FontWeight.bold : FontWeight.normal,
                      fontSize: done ? 12 : 14,
                    ),
                  ),
                  if (done) const Text('🔥', style: TextStyle(fontSize: 8)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //   workout card
  // ──────────────────────────────────────────────
  Widget _buildWorkoutPage(Map<String, dynamic> w) => Column(
    children: [
      const SizedBox(height: 40),

      // title
      AnimatedBuilder(
        animation: _titleGlowAnim,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Text(
              w['title'],
              style: TextStyle(
                fontSize: 32,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = w['glowColor'].withOpacity(
                      0.4 + (_titleGlowAnim.value * 0.2)),
              ),
            ),
            ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(w['darkGlow'], w['lightGlow'], _titleGlowAnim.value)!,
                  Color.lerp(w['lightGlow'], w['glowColor'], _titleGlowAnim.value)!,
                ],
              ).createShader(rect),
              child: Text(w['title'],
                  style: const TextStyle(fontSize: 32, color: Colors.white)),
            ),
          ],
        ),
      ),

      const SizedBox(height: 30),

      Text(w['subtitle'],
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),

      const SizedBox(height: 20),

      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(w['icon'], style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        const Text('Jun 4', style: TextStyle(color: Colors.grey, fontSize: 18)),
      ]),

      const SizedBox(height: 30),

      _buildPageIndicator(),

      const Spacer(),

      _buildStartButton(w),

      const SizedBox(height: 30),

      _buildDurationSelector(),

      const SizedBox(height: 40),
    ],
  );

  // indicator
  Widget _buildPageIndicator() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      workouts.length,
          (idx) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentPage == idx ? Colors.white : Colors.grey.shade600,
        ),
      ),
    ),
  );

  // ──────────────────────────────────────────────
  //   start button (sole glow)
  // ──────────────────────────────────────────────
  Widget _buildStartButton(Map<String, dynamic> w) => AnimatedBuilder(
    animation: _glowAnim,
    builder: (_, __) => GestureDetector(
      onTap: () {
        // TODO: launch workout
      },
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: w['glowColor'].withOpacity(_glowAnim.value),
              blurRadius: 40 + (_glowAnim.value * 20),
              spreadRadius: 10 + (_glowAnim.value * 15),
            ),
            BoxShadow(
                color: w['glowColor'].withOpacity(0.2),
                blurRadius: 60,
                spreadRadius: 30),
          ],
        ),
        child: const Center(
          child: Text('Start',
              style: TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold)),
        ),
      ),
    ),
  );

  // ──────────────────────────────────────────────
  //   duration selector
  // ──────────────────────────────────────────────
  Widget _buildDurationSelector() => GestureDetector(
    onTap: _showDurationPicker,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(
          color: Colors.grey.shade900, borderRadius: BorderRadius.circular(25)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(_selectedDuration,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(width: 10),
        const Icon(Icons.swap_vert, color: Colors.white, size: 20),
      ]),
    ),
  );

  void _showDurationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        const options = ['5 min', '10 min', '15 min', '20 min', '30 min'];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Select Duration',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...options.map(
                  (d) => ListTile(
                title: Text(d, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() => _selectedDuration = d);
                  Navigator.pop(context);
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  //   bottom nav
  // ──────────────────────────────────────────────
  Widget _buildBottomNavigation() => Padding(
    padding: const EdgeInsets.only(bottom: 20, top: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavItem(Icons.home, 'Home', true),
        _buildNavItem(Icons.emoji_events, 'Challenges', false),
        _buildNavItem(Icons.calendar_month, 'Calendar', false),
        _buildNavItem(Icons.person, 'Profile', false),
      ],
    ),
  );

  Widget _buildNavItem(IconData icon, String label, bool sel) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: sel ? Colors.white : Colors.grey.shade600, size: 28),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(color: sel ? Colors.white : Colors.grey.shade600, fontSize: 12)),
    ],
  );
}
