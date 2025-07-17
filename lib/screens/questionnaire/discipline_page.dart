// discipline_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sport_disciplines_data.dart';

class DisciplinePage extends StatefulWidget {
  final Function(List<Map<String, String>>) onSelected;
  final List<Map<String, String>>? selectedValue;
  final String selectedSport;
  final VoidCallback onGenderConflict;

  const DisciplinePage({
    Key? key,
    required this.onSelected,
    this.selectedValue,
    required this.selectedSport,
    required this.onGenderConflict,
  }) : super(key: key);

  @override
  State<DisciplinePage> createState() => _DisciplinePageState();
}

class _DisciplinePageState extends State<DisciplinePage> with TickerProviderStateMixin {
  List<Map<String, String>> selected = [];
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, String>> availableDisciplines = [];

  @override
  void initState() {
    super.initState();
    selected = widget.selectedValue ?? [];

    // Get disciplines for the selected sport
    availableDisciplines = SportDisciplines.disciplines[widget.selectedSport] ?? [];

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
      availableDisciplines.length,
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

  bool _hasGenderConflict(Map<String, String> discipline) {
    if (selected.isEmpty) return false;

    // Get all unique genders from selected disciplines
    Set<String> selectedGenders = selected
        .map((d) => d['gender'] ?? '')
        .where((g) => g != 'Mixed')
        .toSet();

    String newGender = discipline['gender'] ?? '';

    // If new discipline is mixed, no conflict
    if (newGender == 'Mixed') return false;

    // If there are already non-mixed genders selected and they differ from new one
    if (selectedGenders.isNotEmpty && !selectedGenders.contains(newGender)) {
      return true;
    }

    return false;
  }

  void _toggleDiscipline(Map<String, String> discipline) {
    setState(() {
      bool isSelected = selected.any((d) =>
      d['name'] == discipline['name'] && d['gender'] == discipline['gender']
      );

      if (isSelected) {
        selected.removeWhere((d) =>
        d['name'] == discipline['name'] && d['gender'] == discipline['gender']
        );
      } else {
        // Check for gender conflict
        if (_hasGenderConflict(discipline)) {
          widget.onGenderConflict();
          return;
        }
        selected.add(discipline);
      }
    });
    widget.onSelected(selected);
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
                  'Select your discipline(s) in ${widget.selectedSport}. Choose all that apply to receive training tailored to your specific needs.',
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

              // Disciplines list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availableDisciplines.length,
                itemBuilder: (context, index) {
                  final discipline = availableDisciplines[index];
                  final isSelected = selected.any((d) =>
                  d['name'] == discipline['name'] && d['gender'] == discipline['gender']
                  );

                  return AnimatedBuilder(
                    animation: _animations[index],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animations[index].value,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildDisciplineCard(discipline, isSelected),
                        ),
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

  Widget _buildDisciplineCard(Map<String, String> discipline, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleDiscipline(discipline),
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
        child: Row(
          children: [
            // Discipline name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discipline['name'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: Colors.white.withOpacity(isSelected ? 1 : 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getGenderColor(discipline['gender']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      discipline['gender'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getGenderColor(discipline['gender']),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white.withOpacity(0.2),
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
    );
  }

  Color _getGenderColor(String? gender) {
    switch (gender) {
      case 'Men':
        return Colors.blue[400]!;
      case 'Women':
        return Colors.pink[400]!;
      case 'Mixed':
        return Colors.purple[400]!;
      default:
        return Colors.white;
    }
  }
}