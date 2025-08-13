import 'discipline_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'age_page.dart';
import 'goals_page.dart';
import 'equipment_page.dart';
import 'injuries_page.dart';
import 'sport_page.dart';
import 'training_hours_page.dart';
import 'flexibility_page.dart';
import '../home_screen.dart';
import '../schedule_screen.dart';
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
  late AnimationController _errorController;
  late Animation<double> _buttonAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _errorSlideAnimation;
  late Animation<double> _errorFadeAnimation;

  // Error notification state
  bool _showError = false;
  String _errorMessage = '';

  // Store all questionnaire responses
  Map<String, dynamic> _responses = {};

  final List<String> _pageNames = [
    'AGE',
    'SPORT',
    'DISCIPLINE',
    'GOALS',
    'EQUIPMENT',
    'INJURIES',
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

    _errorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

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

    _errorSlideAnimation = Tween<double>(
      begin: -200.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.easeOutCubic,
    ));

    _errorFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    _glowController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Age page
        return _responses['age'] != null && _responses['age'].isNotEmpty;
      case 1: // Sport page
        return _responses['sport'] != null && _responses['sport'].isNotEmpty;
      case 2: // Discipline page
        return _responses['disciplines'] != null && (_responses['disciplines'] as List).isNotEmpty;
      case 3: // Goals page
        return _responses['goals'] != null && (_responses['goals'] as List).isNotEmpty;
      case 4: // Equipment page
        return _responses['equipment'] != null && (_responses['equipment'] as List).isNotEmpty;
      case 5: // Injuries page
        return _responses['injuries'] != null && (_responses['injuries'] as List).isNotEmpty;
      case 6: // Training hours page
        return _responses['training_hours'] != null && _responses['training_hours'].isNotEmpty;
      case 7: // Flexibility page
        return _responses['flexibility'] != null && _responses['flexibility'].isNotEmpty;
      default:
        return false;
    }
  }

  String _getValidationMessage() {
    switch (_currentPage) {
      case 0:
        return 'Please select your age';
      case 1:
        return 'Please select your sport';
      case 2:
        return 'Please select at least one discipline';
      case 3:
        return 'Please select at least one goal';
      case 4:
        return 'Please select at least one equipment option';
      case 5:
        return 'Please select at least one option';
      case 6:
        return 'Please select your training hours';
      case 7:
        return 'Please select your flexibility level';
      default:
        return 'Please make a selection';
    }
  }

  void _nextPage() {
    if (!_validateCurrentPage()) {
      _showValidationError(_getValidationMessage());
      return;
    }

    if (_currentPage < 7) {
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
      // Clear disciplines if going back from discipline page
      if (_currentPage == 2) {
        setState(() {
          _responses.remove('disciplines');
        });
      }
      // Clear goals if going back from goals page
      if (_currentPage == 3) {
        setState(() {
          _responses.remove('goals');
        });
      }

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

  void _showValidationError(String message) {
    setState(() {
      _showError = true;
      _errorMessage = message;
    });

    _errorController.forward();
    HapticFeedback.mediumImpact();

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _errorController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showError = false;
            });
          }
        });
      }
    });
  }

  void _showGoalsError() {
    _showValidationError('Maximum 3 goals can be selected');
  }

  void _showGenderConflictError() {
    _showValidationError('Please select disciplines from the same gender category only');
  }

  Future<void> _submitQuestionnaire() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Extract gender from selected disciplines
        String? gender;
        if (_responses['disciplines'] != null && (_responses['disciplines'] as List).isNotEmpty) {
          final disciplines = _responses['disciplines'] as List<Map<String, String>>;
          // Get the first non-mixed gender
          for (var discipline in disciplines) {
            if (discipline['gender'] != 'Mixed') {
              gender = discipline['gender'];
              break;
            }
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'profile': {
            ..._responses,
            'gender': gender, // Add extracted gender
          },
          'questionnaire_completed': true,
          'completed_at': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ScheduleScreen()),
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
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content with header
          Column(
            children: [
              // Header
              Container(
                color: Colors.black,
                padding: EdgeInsets.only(
                  top: statusBarHeight + 20,
                  left: 24,
                  right: 24,
                  bottom: 12,
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
                                '${_currentPage + 1} of 8',
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
                          _pageNames[_currentPage],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress bar
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (_currentPage + 1) / 8,
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

              // Pages
              Expanded(
                child: PageView(
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
                    SportPage(
                      onSelected: (value) => _updateResponse('sport', value),
                      selectedValue: _responses['sport'],
                    ),
                    DisciplinePage(
                      onSelected: (value) => _updateResponse('disciplines', value),
                      selectedValue: _responses['disciplines'],
                      selectedSport: _responses['sport'] ?? '',
                      onGenderConflict: _showGenderConflictError,
                    ),
                    GoalsPage(
                      onSelected: (value) => _updateResponse('goals', value),
                      selectedValue: _responses['goals'],
                      onMaxGoalsExceeded: _showGoalsError,
                      selectedSport: _responses['sport'] ?? '',
                      selectedDisciplines: _responses['disciplines'] ?? [],
                    ),
                    EquipmentPage(
                      onSelected: (value) => _updateResponse('equipment', value),
                      selectedValue: _responses['equipment'],
                    ),
                    InjuriesPage(
                      onSelected: (value) => _updateResponse('injuries', value),
                      selectedValue: _responses['injuries'],
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
              ),
            ],
          ),

          // Continue button
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
                                _currentPage == 7 ? 'Complete' : 'Continue',
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

          // Error notification overlay - positioned absolutely at the top
          if (_showError)
            AnimatedBuilder(
              animation: _errorController,
              builder: (context, child) {
                return Positioned(
                  top: _errorSlideAnimation.value,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _errorFadeAnimation,
                    child: Container(
                      margin: EdgeInsets.only(
                        top: statusBarHeight + 8,
                        left: 24,
                        right: 24,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A0000), // Very dark red, almost black
                            Color(0xFF2D0000), // Matching the goal card gradient style
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.warning_rounded,
                              color: Colors.red[400],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}