import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoalsPage extends StatefulWidget {
  final Function(List<String>) onSelected;
  final List<String>? selectedValue;

  const GoalsPage({
    Key? key,
    required this.onSelected,
    this.selectedValue,
  }) : super(key: key);

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with TickerProviderStateMixin {
  late List<String> selected;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showError = false;
  String _errorMessage = '';

  final List<Map<String, dynamic>> goals = [
    {
      'title': 'Increase Vertical Jump',
      'icon': '🚀',
      'description': 'Jump higher, reach further',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'title': 'Improve Agility/Speed',
      'icon': '⚡',
      'description': 'Move faster, react quicker',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'title': 'Build Sport-Specific Strength',
      'icon': '💪',
      'description': 'Targeted muscle development',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'title': 'Enhance Flexibility/Mobility',
      'icon': '🧘',
      'description': 'Greater range of motion',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'title': 'Improve Endurance/Stamina',
      'icon': '🏃',
      'description': 'Last longer, go further',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'title': 'Develop Power/Explosiveness',
      'icon': '💥',
      'description': 'Maximum force output',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
  ];

  @override
  void initState() {
    super.initState();
    selected = widget.selectedValue ?? [];

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
      goals.length,
          (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 100)),
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

  void _toggleGoal(String goal) {
    setState(() {
      if (selected.contains(goal)) {
        selected.remove(goal);
        _showError = false;
      } else if (selected.length < 3) {
        selected.add(goal);
        _showError = false;
      } else {
        // Show error message
        _showError = true;
        _errorMessage = 'Maximum 3 goals can be selected';
        HapticFeedback.heavyImpact();

        // Hide error after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showError = false;
            });
          }
        });
      }
      widget.onSelected(selected);
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Main scrollable content
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 100,
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
                      'These goals help PeakFit personalize your athletic training program. You\'ll have the opportunity to update your goals every 6 weeks as you progress and evolve in your fitness journey.',
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

                  const SizedBox(height: 24),

                  // Selection indicator
                  Column(
                    children: [
                      Text(
                        '${selected.length}/3 goals selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final isFilled = index < selected.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.transparent,
                              border: Border.all(
                                color: Colors.white.withOpacity(isFilled ? 0.8 : 0.3),
                                width: 1.5,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Goals list
                  ...List.generate(goals.length, (index) {
                    final goal = goals[index];
                    final isSelected = selected.contains(goal['title']);

                    return AnimatedBuilder(
                      animation: _animations[index],
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _animations[index].value,
                          child: _buildGoalCard(goal, isSelected),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),

            // Error message at top
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showError ? MediaQuery.of(context).padding.top + 80 : -100,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[300],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 14,
                        ),
                      ),
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

  Widget _buildGoalCard(Map<String, dynamic> goal, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _toggleGoal(goal['title']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: goal['gradient'],
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
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ] : [],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    goal['icon'],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['title'],
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal['description'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.4)
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}