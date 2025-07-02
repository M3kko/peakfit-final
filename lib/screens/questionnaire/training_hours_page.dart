import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TrainingHoursPage extends StatefulWidget {
  final Function(String) onSelected;
  final String? selectedValue;

  const TrainingHoursPage({
    Key? key,
    required this.onSelected,
    this.selectedValue,
  }) : super(key: key);

  @override
  State<TrainingHoursPage> createState() => _TrainingHoursPageState();
}

class _TrainingHoursPageState extends State<TrainingHoursPage> with TickerProviderStateMixin {
  String? selected;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> trainingHours = [
    {
      'range': '1-5 hours',
      'icon': '🏃‍♂️',
      'description': 'Light training load',
      'color': Color(0xFF6FCF97),
    },
    {
      'range': '6-10 hours',
      'icon': '💪',
      'description': 'Moderate commitment',
      'color': Color(0xFF56CCF2),
    },
    {
      'range': '11-15 hours',
      'icon': '🔥',
      'description': 'Serious training',
      'color': Color(0xFFF2994A),
    },
    {
      'range': '16-20 hours',
      'icon': '⚡',
      'description': 'High performance',
      'color': Color(0xFFEB5757),
    },
    {
      'range': '20+ hours',
      'icon': '🚀',
      'description': 'Elite level',
      'color': Color(0xFF9B51E0),
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
      trainingHours.length,
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

  void _selectHours(String hours) {
    setState(() {
      selected = hours;
    });
    widget.onSelected(hours);
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
                  'How many hours do you train per week? This includes all sports practice, gym sessions, and dedicated training time. PeakFit will balance your workload accordingly.',
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

              const SizedBox(height: 30),

              // Training hours options
              ...List.generate(trainingHours.length, (index) {
                final hours = trainingHours[index];
                final isSelected = selected == hours['range'];

                return AnimatedBuilder(
                  animation: _animations[index],
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animations[index].value,
                      child: _buildHoursCard(hours, isSelected, index),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoursCard(Map<String, dynamic> hours, bool isSelected, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _selectHours(hours['range']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
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
          child: Row(
            children: [
              // Icon with progress indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  // Progress circle
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: (index + 1) / trainingHours.length,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hours['color'].withOpacity(isSelected ? 0.8 : 0.4),
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  // Icon
                  Text(
                    hours['icon'],
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hours['range'],
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hours['description'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

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
      ),
    );
  }
}