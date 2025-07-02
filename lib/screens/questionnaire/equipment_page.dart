import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EquipmentPage extends StatefulWidget {
  final Function(List<String>) onSelected;
  final List<String>? selectedValue;

  const EquipmentPage({
    Key? key,
    required this.onSelected,
    this.selectedValue,
  }) : super(key: key);

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> with TickerProviderStateMixin {
  late List<String> selected;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> equipment = [
    {
      'name': 'None',
      'subtitle': '(bodyweight only)',
      'icon': '💪',
      'description': 'Pure body control',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'name': 'Jump rope',
      'icon': '🏃',
      'description': 'Cardio & coordination',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'name': 'Resistance bands',
      'icon': '🔗',
      'description': 'Variable resistance',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'name': 'Dumbbells',
      'icon': '🏋️',
      'description': 'Strength building',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'name': 'Plyometric box',
      'icon': '📦',
      'description': 'Explosive power',
      'gradient': [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)],
    },
    {
      'name': 'Balance board',
      'icon': '⚖️',
      'description': 'Stability & control',
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
      equipment.length,
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

  void _toggleEquipment(String item) {
    setState(() {
      if (selected.contains(item)) {
        selected.remove(item);
      } else {
        selected.add(item);
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
        child: Column(
          children: [
            // Description paragraph with its own padding
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
              child: Text(
                'PeakFit creates primarily bodyweight-based workouts designed for athletic performance. While equipment isn\'t required, having access to certain tools can enhance your training and unlock additional exercise variations. You can update your equipment anytime in settings.',
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

            const SizedBox(height: 24), // Space between paragraph and grid

            // Equipment grid in expanded scroll view
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: 120,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: equipment.length,
                  itemBuilder: (context, index) {
                    final item = equipment[index];
                    final isSelected = selected.contains(item['name']);

                    return AnimatedBuilder(
                      animation: _animations[index],
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _animations[index].value,
                          child: _buildEquipmentCard(item, isSelected),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> item, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleEquipment(item['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item['gradient'],
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['icon'],
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: item['name'] == 'None' ? 18 : 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  if (item['subtitle'] != null)
                    Text(
                      item['subtitle'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}