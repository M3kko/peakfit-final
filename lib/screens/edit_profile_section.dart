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

  // Animation controllers
  late AnimationController _buttonController;
  late AnimationController _glowController;
  late Animation<double> _buttonAnimation;
  late Animation<double> _glowAnimation;

  Map<String, dynamic> _tempData = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tempData = Map.from(widget.profileData['profile'] ?? {});
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

  int _getInitialPage() {
    switch (widget.section) {
      case 'personal':
        return 0;
      case 'goals':
        return 2;
      case 'equipment':
        return 3;
      case 'schedule':
        return 4;
      case 'condition':
        return 5;
      default:
        return 0;
    }
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return 'PERSONAL INFO';
      case 1:
        return 'DISCIPLINES';
      case 2:
        return 'FITNESS GOALS';
      case 3:
        return 'EQUIPMENT';
      case 4:
        return 'TRAINING HOURS';
      case 5:
        return 'INJURIES';
      case 6:
        return 'FLEXIBILITY';
      default:
        return 'EDIT PROFILE';
    }
  }

  Widget _buildPage() {
    switch (_currentPage) {
      case 0:
        return Column(
          children: [
            Expanded(
              child: AgePage(
                onSelected: (value) => _updateTempData('age', value),
                selectedValue: _tempData['age'],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SportPage(
                onSelected: (value) {
                  _updateTempData('sport', value);
                  // Clear disciplines when sport changes
                  _tempData.remove('disciplines');
                },
                selectedValue: _tempData['sport'],
              ),
            ),
          ],
        );
      case 1:
        return DisciplinePage(
          onSelected: (value) => _updateTempData('disciplines', value),
          selectedValue: _tempData['disciplines'],
          selectedSport: _tempData['sport'] ?? '',
          onGenderConflict: _showGenderConflictError,
        );
      case 2:
        return GoalsPage(
          onSelected: (value) => _updateTempData('goals', value),
          selectedValue: _tempData['goals'],
          selectedSport: _tempData['sport'] ?? '',
          selectedDisciplines: _tempData['disciplines'] ?? [],
          onMaxGoalsExceeded: _showMaxGoalsError,
        );
      case 3:
        return EquipmentPage(
          onSelected: (value) => _updateTempData('equipment', value),
          selectedValue: _tempData['equipment'],
        );
      case 4:
        return TrainingHoursPage(
          onSelected: (value) => _updateTempData('training_hours', value),
          selectedValue: _tempData['training_hours'],
        );
      case 5:
        return InjuriesPage(
          onSelected: (value) => _updateTempData('injuries', value),
          selectedValue: _tempData['injuries'],
        );
      case 6:
        return FlexibilityPage(
          onSelected: (value) => _updateTempData('flexibility', value),
          selectedValue: _tempData['flexibility'],
        );
      default:
        return const SizedBox();
    }
  }

  void _updateTempData(String key, dynamic value) {
    setState(() {
      _tempData[key] = value;
      _hasChanges = true;
    });
  }

  void _showGenderConflictError() {
    _showError('Please select disciplines from the same gender category only');
  }

  void _showMaxGoalsError() {
    _showError('Maximum 3 goals can be selected');
  }

  void _showError(String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
    } catch (e) {
      _showError('Error updating profile: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
                children: pages.map((page) => page).toList(),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
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

  Widget _buildNavigationButtons() {
    final pages = _getPages();
    final isLastPage = _currentPage == pages.length - 1;
    final isFirstPage = _currentPage == 0;

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

  List<Widget> _getPages() {
    switch (widget.section) {
      case 'personal':
        return [
          Column(
            children: [
              Expanded(
                child: AgePage(
                  onSelected: (value) => _updateTempData('age', value),
                  selectedValue: _tempData['age'],
                ),
              ),
            ],
          ),
          SportPage(
            onSelected: (value) {
              _updateTempData('sport', value);
              _tempData.remove('disciplines');
            },
            selectedValue: _tempData['sport'],
          ),
          if (_tempData['sport'] != null)
            DisciplinePage(
              onSelected: (value) => _updateTempData('disciplines', value),
              selectedValue: _tempData['disciplines'],
              selectedSport: _tempData['sport'] ?? '',
              onGenderConflict: _showGenderConflictError,
            ),
        ];
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
}