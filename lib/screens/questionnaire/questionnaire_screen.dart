import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../weekly_plan_screen.dart';
import 'age_page.dart';
import 'goals_page.dart';
import 'equipment_page.dart';
import 'injuries_page.dart';
import 'sport_page.dart';
import 'training_hours_page.dart';
import 'flexibility_page.dart';

class QuestionnaireScreen extends StatefulWidget {
  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> with TickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation controllers
  late AnimationController _buttonController;
  late AnimationController _glowController;
  late Animation<double> _buttonAnimation;
  late Animation<double> _glowAnimation;

  // Store all questionnaire responses
  Map<String, dynamic> _responses = {};

  final List<String> _pageNames = [
    'AGE',
    'GOALS',
    'EQUIPMENT',
    'INJURIES',
    'SPORT',
    'TRAINING',
    'FLEXIBILITY',
  ];

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _submitQuestionnaire();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateResponse(String key, dynamic value) {
    setState(() {
      _responses[key] = value;
    });
  }

  Future<void> _submitQuestionnaire() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'profile': _responses,
          'created_at': FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WeeklyPlanScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main page content
          PageView(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AgePage(
                onSelected: (value) => _updateResponse('age', value),
                selectedValue: _responses['age'],
              ),
              GoalsPage(
                onSelected: (value) => _updateResponse('goals', value),
                selectedValue: _responses['goals'],
              ),
              EquipmentPage(
                onSelected: (value) => _updateResponse('equipment', value),
                selectedValue: _responses['equipment'],
              ),
              InjuriesPage(
                onSelected: (value) => _updateResponse('injuries', value),
                selectedValue: _responses['injuries'],
              ),
              SportPage(
                onSelected: (value) => _updateResponse('sport', value),
                selectedValue: _responses['sport'],
              ),
              TrainingHoursPage(
                onSelected: (value) => _updateResponse('training_hours', value),
                selectedValue: _responses['training_hours'],
              ),
              FlexibilityPage(
                onSelected: (value) => _updateResponse('flexibility', value),
                selectedValue: _responses['flexibility'],
              ),
            ],
          ),

          // Header directly at top
          Container(
            color: Colors.black,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top, // This accounts for status bar
              left: 24,
              right: 24,
              bottom: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Navigation row
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: _currentPage > 0 ? _previousPage : null,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _currentPage > 0
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _currentPage > 0
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: _currentPage > 0
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.2),
                              size: 24,
                            ),
                          ),
                        ),

                        // Step indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            '${_currentPage + 1} of 7',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Title
                    Text(
                      'Assessment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Progress bar
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_currentPage + 1) / 7,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Continue button at bottom
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: GestureDetector(
              onTap: _nextPage,
              onTapDown: (_) => _buttonController.forward(),
              onTapUp: (_) => _buttonController.reverse(),
              onTapCancel: () => _buttonController.reverse(),
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return AnimatedBuilder(
                    animation: _buttonAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonAnimation.value,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(_glowAnimation.value),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == 6 ? 'Complete' : 'Continue',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.black,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}