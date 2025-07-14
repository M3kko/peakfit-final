import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GenderPage extends StatefulWidget {
  final Function(String) onSelected;
  final String? selectedValue;

  const GenderPage({
    Key? key,
    required this.onSelected,
    this.selectedValue,
  }) : super(key: key);

  @override
  State<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> with TickerProviderStateMixin {
  String? selected;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> genders = [
    {
      'value': 'Male',
      'icon': '♂️',
      'description': 'Biological male',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'value': 'Female',
      'icon': '♀️',
      'description': 'Biological female',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
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
      genders.length,
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

  void _selectGender(String gender) {
    setState(() {
      selected = gender;
    });
    widget.onSelected(gender);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Description paragraph at the top
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
              child: Text(
                'Select your biological gender. This helps PeakFit tailor training recommendations based on physiological differences and optimize your workout program.',
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

            // Centered content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(genders.length, (index) {
                      final gender = genders[index];
                      final isSelected = selected == gender['value'];

                      return AnimatedBuilder(
                        animation: _animations[index],
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _animations[index].value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: _buildGenderCard(gender, isSelected),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 120), // Space for continue button
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard(Map<String, dynamic> gender, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectGender(gender['value']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 160,
        height: 308, // Increased by 40% from 220
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gender['gradient'],
          )
              : null,
          color: !isSelected ? Colors.white.withOpacity(0.05) : null,
          borderRadius: BorderRadius.circular(24),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon without background - white icon
            Text(
              gender['icon'],
              style: TextStyle(
                fontSize: 72,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                shadows: isSelected ? [
                  Shadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ] : null,
              ),
            ),
            const SizedBox(height: 32),

            // Text content
            Text(
              gender['value'],
              style: TextStyle(
                fontSize: 20,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              gender['description'],
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 24),

            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}