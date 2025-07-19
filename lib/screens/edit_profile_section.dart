import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'questionnaire/age_page.dart';
import 'questionnaire/sport_page.dart';
import 'questionnaire/discipline_page.dart';
import 'questionnaire/goals_page.dart';
import 'questionnaire/equipment_page.dart';
import 'questionnaire/injuries_page.dart';
import 'questionnaire/training_hours_page.dart';
import 'questionnaire/flexibility_page.dart';

class EditProfileSection extends StatefulWidget {
  final String section;
  final Map<String, dynamic> profileData;
  final VoidCallback onUpdate;

  const EditProfileSection({
    Key? key,
    required this.section,
    required this.profileData,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditProfileSection> createState() => _EditProfileSectionState();
}

class _EditProfileSectionState extends State<EditProfileSection> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late PageController _pageController;
  int _currentPage = 0;

  late AnimationController _buttonController;
  late AnimationController _glowController;
  late AnimationController _notificationController;
  late Animation<double> _buttonAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _notificationSlideAnimation;
  late Animation<double> _notificationFadeAnimation;

  Map<String, dynamic> _tempData = {};
  bool _hasChanges = false;

  // Notification state
  bool _showNotification = false;
  String _notificationMessage = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();

    // Initialize temp data from profile, handling null cases
    if (widget.profileData['profile'] != null) {
      _tempData = Map<String, dynamic>.from(widget.profileData['profile']);
    }

    _pageController = PageController(initialPage: _getInitialPage());
    _currentPage = _getInitialPage();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _notificationController = AnimationController(
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

    _notificationSlideAnimation = Tween<double>(
      begin: -200.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _notificationController,
      curve: Curves.easeOutCubic,
    ));

    _notificationFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _notificationController,
      curve: Curves.easeIn,
    ));
  }

  int _getInitialPage() {
    switch (widget.section) {
      case 'personal':
        return 0;
      case 'goals':
        return 0; // Goals is now the first page
      case 'equipment':
        return 0;
      case 'schedule':
        return 0;
      case 'condition':
        return 0;
      default:
        return 0;
    }
  }

  String _getPageTitle() {
    final pages = _getPages();
    if (_currentPage >= 0 && _currentPage < pages.length) {
      switch (widget.section) {
        case 'personal':
          return ['AGE', 'SPORT', 'DISCIPLINE'][_currentPage];
        case 'goals':
          return 'FITNESS GOALS';
        case 'equipment':
          return 'EQUIPMENT';
        case 'schedule':
          return 'TRAINING HOURS';
        case 'condition':
          return ['INJURIES', 'FLEXIBILITY'][_currentPage];
        default:
          return 'EDIT PROFILE';
      }
    }
    return 'EDIT PROFILE';
  }

  void _updateTempData(String key, dynamic value) {
    setState(() {
      _tempData[key] = value;
      _hasChanges = true;
    });
  }

  void _showError(String message) {
    _showNotificationMessage(message, isError: true);
  }

  void _showNotificationMessage(String message, {bool isError = false}) {
    setState(() {
      _showNotification = true;
      _notificationMessage = message;
      _isError = isError;
    });

    _notificationController.forward();
    HapticFeedback.mediumImpact();

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _notificationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showNotification = false;
            });
          }
        });
      }
    });
  }

  void _showGenderConflictError() {
    _showError('Please select disciplines from the same gender category only');
  }

  void _showMaxGoalsError() {
    _showError('Maximum 3 goals can be selected');
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || user == null) return;

    try {
      // Extract gender from disciplines if present
      String? gender;
      if (_tempData['disciplines'] != null && (_tempData['disciplines'] as List).isNotEmpty) {
        final disciplines = _tempData['disciplines'] as List<Map<String, String>>;
        for (var discipline in disciplines) {
          if (discipline['gender'] != 'Mixed') {
            gender = discipline['gender'];
            break;
          }
        }
      }

      // Update user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'profile': {
          ..._tempData,
          if (gender != null) 'gender': gender,
        },
        'updated_at': FieldValue.serverTimestamp(),
      });

      widget.onUpdate();

      if (mounted) {
        Navigator.pop(context);
        // Show success message in parent screen if needed
      }
    } catch (e) {
      _showError('Error updating profile: ${e.toString()}');
    }
  }

  List<Widget> _getPages() {
    switch (widget.section) {
      case 'personal':
        List<Widget> pages = [
          AgePage(
            onSelected: (value) => _updateTempData('age', value),
            selectedValue: _tempData['age'],
          ),
          SportPage(
            onSelected: (value) {
              _updateTempData('sport', value);
              _tempData.remove('disciplines');
            },
            selectedValue: _tempData['sport'],
          ),
        ];

        // Only add discipline page if sport is selected
        if (_tempData['sport'] != null && _tempData['sport'].toString().isNotEmpty) {
          pages.add(
            DisciplinePage(
              onSelected: (value) => _updateTempData('disciplines', value),
              selectedValue: _tempData['disciplines'],
              selectedSport: _tempData['sport'] ?? '',
              onGenderConflict: _showGenderConflictError,
            ),
          );
        }
        return pages;

      case 'goals':
        return [
          GoalsPage(
            onSelected: (value) => _updateTempData('goals', value),
            selectedValue: _tempData['goals'],
            selectedSport: _tempData['sport'] ?? '',
            selectedDisciplines: _tempData['disciplines'] ?? [],
            onMaxGoalsExceeded: _showMaxGoalsError,
          ),
        ];

      case 'equipment':
        return [
          EquipmentPage(
            onSelected: (value) => _updateTempData('equipment', value),
            selectedValue: _tempData['equipment'],
          ),
        ];

      case 'schedule':
        return [
          TrainingHoursPage(
            onSelected: (value) => _updateTempData('training_hours', value),
            selectedValue: _tempData['training_hours'],
          ),
        ];

      case 'condition':
        return [
          InjuriesPage(
            onSelected: (value) => _updateTempData('injuries', value),
            selectedValue: _tempData['injuries'],
          ),
          FlexibilityPage(
            onSelected: (value) => _updateTempData('flexibility', value),
            selectedValue: _tempData['flexibility'],
          ),
        ];

      default:
        return [];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    _glowController.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final pages = _getPages();

    if (pages.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No data to edit',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final isLastPage = _currentPage == pages.length - 1;
    final isFirstPage = _currentPage == 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    children: pages,
                  ),
                ),
                _buildNavigationButtons(isFirstPage, isLastPage, pages.length),
              ],
            ),
          ),

          // Notification overlay - positioned absolutely at the top
          if (_showNotification)
            AnimatedBuilder(
              animation: _notificationController,
              builder: (context, child) {
                return Positioned(
                  top: _notificationSlideAnimation.value,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _notificationFadeAnimation,
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
                          colors: _isError
                              ? [
                            const Color(0xFF1A0000), // Very dark red
                            const Color(0xFF2D0000),
                          ]
                              : [
                            const Color(0xFF001A00), // Very dark green
                            const Color(0xFF002D00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _isError
                              ? Colors.red.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isError
                                ? Colors.red.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
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
                              color: _isError
                                  ? Colors.red.withOpacity(0.15)
                                  : Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _isError
                                  ? Icons.warning_rounded
                                  : Icons.check_circle_rounded,
                              color: _isError
                                  ? Colors.red[400]
                                  : Colors.green[400],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _notificationMessage,
                              style: TextStyle(
                                color: _isError
                                    ? Colors.red[300]
                                    : Colors.green[300],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_hasChanges) {
                _showDiscardDialog();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPageTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                if (_hasChanges)
                  Text(
                    'Unsaved changes',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFD4AF37).withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isFirstPage, bool isLastPage, int totalPages) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (!isFirstPage)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!isFirstPage) const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: isLastPage ? _saveChanges : () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
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
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLastPage
                                  ? [const Color(0xFFD4AF37), const Color(0xFFB8941F)]
                                  : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: (isLastPage ? const Color(0xFFD4AF37) : Colors.white)
                                    .withOpacity(_glowAnimation.value),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isLastPage ? 'Save Changes' : 'Next',
                              style: TextStyle(
                                color: isLastPage ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
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

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        title: const Text(
          'Discard Changes?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );
  }
}