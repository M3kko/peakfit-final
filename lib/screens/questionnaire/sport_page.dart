import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SportPage extends StatefulWidget {
  final Function(String) onSelected;
  final String? selectedValue;

  const SportPage({
    Key? key,
    required this.onSelected,
    this.selectedValue,
  }) : super(key: key);

  @override
  State<SportPage> createState() => _SportPageState();
}

class _SportPageState extends State<SportPage> with TickerProviderStateMixin {
  String? selected;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> allSports = [
    {'name': 'General Fitness', 'icon': '💪'},
    {'name': 'Archery', 'icon': '🏹'},
    {'name': 'Badminton', 'icon': '🏸'},
    {'name': 'Ballet', 'icon': '🩰'},
    {'name': 'Baseball', 'icon': '⚾'},
    {'name': 'Basketball', 'icon': '🏀'},
    {'name': 'Bowling', 'icon': '🎳'},
    {'name': 'Boxing', 'icon': '🥊'},
    {'name': 'Calisthenics', 'icon': '💪'},
    {'name': 'Cheerleading', 'icon': '📣'},
    {'name': 'Cycling', 'icon': '🚴'},
    {'name': 'Dance', 'icon': '💃'},
    {'name': 'Fencing', 'icon': '🤺'},
    {'name': 'Figure Skating', 'icon': '⛸️'},
    {'name': 'Football', 'icon': '🏈'},
    {'name': 'Golf', 'icon': '⛳'},
    {'name': 'Gymnastics', 'icon': '🤸'},
    {'name': 'Ice Hockey', 'icon': '🏒'},
    {'name': 'Martial Arts', 'icon': '🥋'},
    {'name': 'Parkour', 'icon': '🏃‍♂️'},
    {'name': 'Rock Climbing', 'icon': '🧗'},
    {'name': 'Rowing', 'icon': '🚣'},
    {'name': 'Running', 'icon': '🏃'},
    {'name': 'Skiing', 'icon': '⛷️'},
    {'name': 'Snowboarding', 'icon': '🏂'},
    {'name': 'Soccer', 'icon': '⚽'},
    {'name': 'Speed Skating', 'icon': '⛸️'},
    {'name': 'Swimming', 'icon': '🏊'},
    {'name': 'Tennis', 'icon': '🎾'},
    {'name': 'Triathlon', 'icon': '🏊‍♂️'},
    {'name': 'Volleyball', 'icon': '🏐'},
  ];

  @override
  void initState() {
    super.initState();
    selected = widget.selectedValue;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _animationControllers = List.generate(
      allSports.length,
          (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 30)),
        vsync: this,
      ),
    );

    _animations = _animationControllers.map((controller) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        ),
    ).toList();

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      for (var controller in _animationControllers) {
        controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectSport(String sport) {
    setState(() {
      selected = sport;
    });
    widget.onSelected(sport);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 120,
            left: 24,
            right: 24,
          ),
          child: Column(
            children: [
              // Description paragraph
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'What is your main sport? PeakFit will create sport-specific exercises to enhance your performance and address the unique demands of your athletic discipline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // All sports grid including General Fitness
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: allSports.length,
                itemBuilder: (context, index) {
                  final sport = allSports[index];
                  final isSelected = selected == sport['name'];

                  return AnimatedBuilder(
                    animation: _animations[index],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animations[index].value,
                        child: _buildSportCard(sport, isSelected),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportCard(Map<String, dynamic> sport, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectSport(sport['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
          )
              : null,
          color: !isSelected ? Colors.white.withOpacity(0.05) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ]
              : [],
        ),
        child: Stack(
          children: [
            // Selection indicator in corner
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

            // Content centered
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sport['icon'],
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sport['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.white.withOpacity(isSelected ? 1 : 0.8),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}