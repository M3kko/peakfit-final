import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AgePage extends StatefulWidget {
  final Function(String) onSelected;
  final String? selectedValue;

  const AgePage({
    Key? key,
    required this.onSelected,
    this.selectedValue,
  }) : super(key: key);

  @override
  State<AgePage> createState() => _AgePageState();
}

class _AgePageState extends State<AgePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late PageController _pageController;
  int _currentAge = 19;
  final int _minAge = 13;
  final int _maxAge = 65;

  @override
  void initState() {
    super.initState();

    // Initialize age from selected value or default
    if (widget.selectedValue != null) {
      _currentAge = int.tryParse(widget.selectedValue!) ?? 19;
    } else {
      // Schedule the callback for after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelected(_currentAge.toString());
      });
    }

    _pageController = PageController(
      initialPage: _currentAge - _minAge,
      viewportFraction: 0.3,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
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

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final newAge = index + _minAge;
    if (newAge != _currentAge) {
      setState(() {
        _currentAge = newAge;
      });
      // Haptic feedback
      HapticFeedback.lightImpact();
      widget.onSelected(_currentAge.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.only(bottom: 120), // Account for Continue button
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add negative margin to center properly with header
              Transform.translate(
                offset: const Offset(0, -40), // Adjust this value to perfectly center
                child: Column(
                  children: [
                    // YOUR AGE text above
                    Text(
                      'YOUR AGE',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 3,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Age slider
                    SizedBox(
                      height: 200,
                      child: _buildAgeSlider(),
                    ),

                    const SizedBox(height: 40),

                    // YEARS OLD text below
                    Text(
                      'YEARS OLD',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 2,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeSlider() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Center highlight gradient
        Container(
          width: 120,
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(60),
          ),
        ),

        // Selection indicator box
        Container(
          width: 100,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),

        // Age numbers horizontal slider
        PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: _maxAge - _minAge + 1,
          itemBuilder: (context, index) {
            final age = index + _minAge;
            final isSelected = age == _currentAge;
            final distance = (age - _currentAge).abs();

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 64 : (distance == 1 ? 40 : 28),
                      fontWeight: isSelected ? FontWeight.w300 : FontWeight.w200,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(distance == 1 ? 0.5 : 0.2),
                    ),
                    child: Text('$age'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}