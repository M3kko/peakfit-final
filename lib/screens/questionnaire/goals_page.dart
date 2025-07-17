import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sport_goals_data.dart';

class GoalsPage extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSelected;
  final List<Map<String, dynamic>>? selectedValue;
  final VoidCallback? onMaxGoalsExceeded;
  final String selectedSport;
  final List<Map<String, String>> selectedDisciplines;

  const GoalsPage({
    Key? key,
    required this.onSelected,
    this.selectedValue,
    this.onMaxGoalsExceeded,
    required this.selectedSport,
    required this.selectedDisciplines,
  }) : super(key: key);

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with TickerProviderStateMixin {
  late List<Map<String, dynamic>> selected;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> sportSpecificGoals = [];
  List<Map<String, dynamic>> generalGoals = [];

  @override
  void initState() {
    super.initState();
    selected = widget.selectedValue ?? [];

    // Get sport-specific goals based on selected disciplines
    _loadGoals();

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

    int totalGoals = sportSpecificGoals.length + generalGoals.length + 2; // +2 for section headers
    _animationControllers = List.generate(
      totalGoals,
          (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
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

  void _loadGoals() {
    // Get sport-specific goals for each selected discipline
    Set<Map<String, dynamic>> uniqueSportGoals = {};

    for (var discipline in widget.selectedDisciplines) {
      String disciplineName = discipline['name'] ?? '';
      String gender = discipline['gender'] ?? '';

      // Try to get goals by the full discipline name first
      var goals = SportGoals.getGoalsForDiscipline(widget.selectedSport, disciplineName);

      // If no goals found and discipline has gender, try by gender
      if (goals.isEmpty && gender.isNotEmpty && gender != 'Mixed') {
        goals = SportGoals.getGoalsForDiscipline(widget.selectedSport, gender);
      }

      uniqueSportGoals.addAll(goals);
    }

    sportSpecificGoals = uniqueSportGoals.toList();
    generalGoals = SportGoals.generalGoals;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleGoal(Map<String, dynamic> goal) {
    setState(() {
      bool isSelected = selected.any((g) =>
      g['title'] == goal['title'] && g['icon'] == goal['icon']
      );

      if (isSelected) {
        selected.removeWhere((g) =>
        g['title'] == goal['title'] && g['icon'] == goal['icon']
        );
      } else if (selected.length < 3) {
        selected.add(goal);
      } else {
        widget.onMaxGoalsExceeded?.call();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 120,
            left: 24,
            right: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description paragraph
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select up to 3 training goals. Choose from sport-specific goals tailored to your ${widget.selectedSport} disciplines, or general fitness goals. You can update these anytime.',
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
              Center(
                child: Column(
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
                    const SizedBox(height: 8),
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
                                ? const Color(0xFFD4AF37).withOpacity(0.8)
                                : Colors.transparent,
                            border: Border.all(
                              color: isFilled
                                  ? const Color(0xFFD4AF37).withOpacity(0.8)
                                  : Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Build the goals list with sections
              ..._buildGoalsList(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGoalsList() {
    List<Widget> widgets = [];
    int animationIndex = 0;

    // Sport-specific section
    if (sportSpecificGoals.isNotEmpty) {
      widgets.add(
        AnimatedBuilder(
          animation: _animations[animationIndex++],
          builder: (context, child) {
            return Transform.scale(
              scale: _animations[animationIndex - 1].value,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 4),
                child: Text(
                  'SPORT SPECIFIC',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD4AF37),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
      );

      for (var goal in sportSpecificGoals) {
        final isSelected = selected.any((g) =>
        g['title'] == goal['title'] && g['icon'] == goal['icon']
        );

        widgets.add(
          AnimatedBuilder(
            animation: _animations[animationIndex++],
            builder: (context, child) {
              return Transform.scale(
                scale: _animations[animationIndex - 1].value,
                child: _buildGoalCard(goal, isSelected, true),
              );
            },
          ),
        );
      }

      widgets.add(const SizedBox(height: 24));
    }

    // General fitness section
    widgets.add(
      AnimatedBuilder(
        animation: _animations[animationIndex++],
        builder: (context, child) {
          return Transform.scale(
            scale: _animations[animationIndex - 1].value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 4),
              child: Text(
                'OTHER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          );
        },
      ),
    );

    for (var goal in generalGoals) {
      final isSelected = selected.any((g) =>
      g['title'] == goal['title'] && g['icon'] == goal['icon']
      );

      widgets.add(
        AnimatedBuilder(
          animation: _animations[animationIndex++],
          builder: (context, child) {
            return Transform.scale(
              scale: _animations[animationIndex - 1].value,
              child: _buildGoalCard(goal, isSelected, false),
            );
          },
        ),
      );
    }

    return widgets;
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, bool isSelected, bool isSportSpecific) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _toggleGoal(goal),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
            )
                : null,
            color: !isSelected ? Colors.white.withOpacity(0.05) : null,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? isSportSpecific
                  ? const Color(0xFFD4AF37).withOpacity(0.4)
                  : Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: isSportSpecific
                    ? const Color(0xFFD4AF37).withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ]
                : [],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    goal['icon'],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['title'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.white.withOpacity(isSelected ? 1 : 0.85),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      goal['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withOpacity(0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
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