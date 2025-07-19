import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'questionnaire/sport_page.dart';
import 'questionnaire/discipline_page.dart';
import 'questionnaire/goals_page.dart';
import 'questionnaire/equipment_page.dart';
import 'questionnaire/injuries_page.dart';
import 'questionnaire/training_hours_page.dart';
import 'questionnaire/flexibility_page.dart';

class TrainingPreferencesScreen extends StatefulWidget {
  const TrainingPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<TrainingPreferencesScreen> createState() => _TrainingPreferencesScreenState();
}

class _TrainingPreferencesScreenState extends State<TrainingPreferencesScreen> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late PageController _pageController;
  int _currentPage = 0;

  // Animation controllers
  late AnimationController _buttonController;
  late AnimationController _glowController;
  late AnimationController _notificationController;
  late Animation<double> _buttonAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _notificationSlideAnimation;
  late Animation<double> _notificationFadeAnimation;

  // Store responses
  Map<String, dynamic> _responses = {};
  Map<String, dynamic> _originalResponses = {};
  bool _hasChanges = false;
  bool _loading = true;
  String? _previousSport;

  // Notification state
  bool _showNotification = false;
  String _notificationMessage = '';
  bool _isError = false;

  final List<String> _sections = [
    'Sport',
    'Discipline',
    'Goals',
    'Equipment',
    'Injuries',
    'Training Hours',
    'Flexibility',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
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
      begin: -100.0,
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

  Future<void> _loadUserData() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists && doc.data()?['profile'] != null) {
        final profile = doc.data()!['profile'] as Map<String, dynamic>;

        // Debug print to see the data structure
        print('Loading profile data: $profile');

        setState(() {
          _responses = Map<String, dynamic>.from(profile);
          _originalResponses = Map<String, dynamic>.from(profile);
          _previousSport = profile['sport'];
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _loading = false;
      });
      _showGlassyNotification('Error loading profile data', isError: true);
    }
  }

  void _updateResponse(String key, dynamic value) {
    setState(() {
      _responses[key] = value;

      // If sport changed, clear disciplines and goals
      if (key == 'sport' && value != _previousSport) {
        _responses.remove('disciplines');
        _responses.remove('goals');

        // Navigate to discipline page if not already there
        if (_currentPage < 1) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      }

      _checkForChanges();
    });
  }

  void _checkForChanges() {
    bool hasChanges = false;

    // Compare each field
    _responses.forEach((key, value) {
      final originalValue = _originalResponses[key];

      if (value == null && originalValue == null) {
        // Both null, no change
      } else if (value == null || originalValue == null) {
        // One is null, there's a change
        hasChanges = true;
      } else if (key == 'goals') {
        // Special handling for goals - they might be strings or maps
        hasChanges = !_areGoalsEqual(value, originalValue);
      } else if (value is List && originalValue is List) {
        // Compare lists
        if (value.length != originalValue.length) {
          hasChanges = true;
        } else {
          // Deep compare list items
          for (int i = 0; i < value.length; i++) {
            if (value[i].toString() != originalValue[i].toString()) {
              hasChanges = true;
              break;
            }
          }
        }
      } else if (value.toString() != originalValue.toString()) {
        hasChanges = true;
      }
    });

    // Check for removed fields
    _originalResponses.forEach((key, value) {
      if (!_responses.containsKey(key) && value != null) {
        hasChanges = true;
      }
    });

    setState(() {
      _hasChanges = hasChanges;
    });
  }

  bool _areGoalsEqual(dynamic goals1, dynamic goals2) {
    if (goals1 == null && goals2 == null) return true;
    if (goals1 == null || goals2 == null) return false;

    final list1 = goals1 as List;
    final list2 = goals2 as List;

    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      final item1 = list1[i];
      final item2 = list2[i];

      // Get the title from either string or map format
      final title1 = item1 is Map ? item1['title'] : item1.toString();
      final title2 = item2 is Map ? item2['title'] : item2.toString();

      if (title1 != title2) return false;
    }

    return true;
  }

  void _showGlassyNotification(String message, {bool isError = false}) {
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
    _showGlassyNotification('Please select disciplines from the same gender category only', isError: true);
  }

  void _showMaxGoalsError() {
    _showGlassyNotification('Maximum 3 goals can be selected', isError: true);
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || user == null) return;

    try {
      // Prepare data for saving
      Map<String, dynamic> dataToSave = {};

      // Process each field
      _responses.forEach((key, value) {
        if (key == 'goals' && value is List) {
          // Convert goals to string format for storage
          dataToSave[key] = value.map((goal) {
            if (goal is Map) {
              return goal['title'] ?? 'Unknown Goal';
            }
            return goal.toString();
          }).toList();
        } else {
          dataToSave[key] = value;
        }
      });

      // Extract gender from disciplines if present
      String? gender;
      final disciplines = dataToSave['disciplines'];
      if (disciplines != null && disciplines is List && disciplines.isNotEmpty) {
        for (var discipline in disciplines) {
          if (discipline is Map && discipline['gender'] != null && discipline['gender'] != 'Mixed') {
            gender = discipline['gender'].toString();
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
          ...dataToSave,
          if (gender != null) 'gender': gender,
        },
        'updated_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _originalResponses = Map<String, dynamic>.from(dataToSave);
        _previousSport = dataToSave['sport'];
        _hasChanges = false;
      });

      _showGlassyNotification('Preferences updated successfully');

      // Navigate back after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });

    } catch (e) {
      print('Save error: $e');
      _showGlassyNotification('Error updating preferences: ${e.toString()}', isError: true);
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Sport
        return _responses['sport'] != null && _responses['sport'].toString().isNotEmpty;
      case 1: // Discipline
        final disciplines = _responses['disciplines'];
        return disciplines != null && disciplines is List && disciplines.isNotEmpty;
      case 2: // Goals
        final goals = _responses['goals'];
        return goals != null && goals is List && goals.isNotEmpty;
      case 3: // Equipment
        final equipment = _responses['equipment'];
        return equipment != null && equipment is List && equipment.isNotEmpty;
      case 4: // Injuries
        final injuries = _responses['injuries'];
        return injuries != null && injuries is List && injuries.isNotEmpty;
      case 5: // Training hours
        return _responses['training_hours'] != null && _responses['training_hours'].toString().isNotEmpty;
      case 6: // Flexibility
        return _responses['flexibility'] != null && _responses['flexibility'].toString().isNotEmpty;
      default:
        return true;
    }
  }

  bool _validateSection(int index) {
    switch (index) {
      case 0: // Sport
        return _responses['sport'] != null && _responses['sport'].toString().isNotEmpty;
      case 1: // Discipline
        final disciplines = _responses['disciplines'];
        return disciplines != null && disciplines is List && disciplines.isNotEmpty;
      case 2: // Goals
        final goals = _responses['goals'];
        return goals != null && goals is List && goals.isNotEmpty;
      case 3: // Equipment
        final equipment = _responses['equipment'];
        return equipment != null && equipment is List && equipment.isNotEmpty;
      case 4: // Injuries
        final injuries = _responses['injuries'];
        return injuries != null && injuries is List && injuries.isNotEmpty;
      case 5: // Training hours
        return _responses['training_hours'] != null && _responses['training_hours'].toString().isNotEmpty;
      case 6: // Flexibility
        return _responses['flexibility'] != null && _responses['flexibility'].toString().isNotEmpty;
      default:
        return false;
    }
  }

  // Helper method to safely get list values
  List<T> _getListValue<T>(String key, List<T> defaultValue) {
    final value = _responses[key];
    if (value == null) return defaultValue;
    if (value is List<T>) return value;
    if (value is List) {
      try {
        return List<T>.from(value);
      } catch (e) {
        print('Error casting $key: $e');
        return defaultValue;
      }
    }
    return defaultValue;
  }

  // Helper method to safely get disciplines
  List<Map<String, String>> _getDisciplines() {
    final disciplines = _responses['disciplines'];
    if (disciplines == null) return [];
    if (disciplines is List) {
      return disciplines.map((item) {
        if (item is Map<String, String>) {
          return item;
        } else if (item is Map) {
          // Convert Map<String, dynamic> to Map<String, String>
          return item.map((key, value) => MapEntry(key.toString(), value.toString()));
        }
        return <String, String>{};
      }).toList();
    }
    return [];
  }

  // Helper method to safely get goals
  List<Map<String, dynamic>> _getGoals() {
    final goals = _responses['goals'];
    if (goals == null) return [];
    if (goals is List) {
      return goals.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is String) {
          // Convert string goals to map format
          return {
            'title': item,
            'icon': '🎯',
            'description': 'Custom goal',
          };
        } else if (item is Map) {
          // Convert any Map to Map<String, dynamic>
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
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

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD4AF37),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSectionList(),
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
                      SportPage(
                        onSelected: (value) => _updateResponse('sport', value),
                        selectedValue: _responses['sport']?.toString(),
                      ),
                      DisciplinePage(
                        onSelected: (value) => _updateResponse('disciplines', value),
                        selectedValue: _getDisciplines(),
                        selectedSport: _responses['sport']?.toString() ?? '',
                        onGenderConflict: _showGenderConflictError,
                      ),
                      GoalsPage(
                        onSelected: (value) => _updateResponse('goals', value),
                        selectedValue: _getGoals(),
                        selectedSport: _responses['sport']?.toString() ?? '',
                        selectedDisciplines: _getDisciplines(),
                        onMaxGoalsExceeded: _showMaxGoalsError,
                      ),
                      EquipmentPage(
                        onSelected: (value) => _updateResponse('equipment', value),
                        selectedValue: _getListValue<String>('equipment', []),
                      ),
                      InjuriesPage(
                        onSelected: (value) => _updateResponse('injuries', value),
                        selectedValue: _getListValue<String>('injuries', []),
                      ),
                      TrainingHoursPage(
                        onSelected: (value) => _updateResponse('training_hours', value),
                        selectedValue: _responses['training_hours']?.toString(),
                      ),
                      FlexibilityPage(
                        onSelected: (value) => _updateResponse('flexibility', value),
                        selectedValue: _responses['flexibility']?.toString(),
                      ),
                    ],
                  ),
                ),
                _buildSaveButton(),
              ],
            ),
          ),

          // Glassy notification overlay
          if (_showNotification)
            AnimatedBuilder(
              animation: _notificationController,
              builder: (context, child) {
                return Positioned(
                  top: statusBarHeight + _notificationSlideAnimation.value,
                  left: 24,
                  right: 24,
                  child: FadeTransition(
                    opacity: _notificationFadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isError
                            ? Colors.red.withOpacity(0.05)
                            : Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isError
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ColorFilter.mode(
                            _isError
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            BlendMode.overlay,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Icon(
                                  _isError
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline,
                                  color: _isError
                                      ? Colors.red[300]
                                      : Colors.green[300],
                                  size: 24,
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
                const Text(
                  'TRAINING PREFERENCES',
                  style: TextStyle(
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

  Widget _buildSectionList() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final isActive = _currentPage == index;
          final isCompleted = _validateSection(index);

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFD4AF37).withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFD4AF37).withOpacity(0.5)
                      : isCompleted
                      ? const Color(0xFFD4AF37).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  if (isCompleted && !isActive)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: const Color(0xFFD4AF37).withOpacity(0.8),
                      ),
                    ),
                  Text(
                    _sections[index],
                    style: TextStyle(
                      fontSize: 14,
                      color: isActive
                          ? const Color(0xFFD4AF37)
                          : isCompleted
                          ? const Color(0xFFD4AF37).withOpacity(0.8)
                          : Colors.white.withOpacity(0.6),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    final allSectionsValid = List.generate(7, (index) => _validateSection(index))
        .every((valid) => valid);

    return Container(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: allSectionsValid && _hasChanges ? _saveChanges : null,
        onTapDown: (_) {
          if (allSectionsValid && _hasChanges) _buttonController.forward();
        },
        onTapUp: (_) {
          if (allSectionsValid && _hasChanges) _buttonController.reverse();
        },
        onTapCancel: () {
          if (allSectionsValid && _hasChanges) _buttonController.reverse();
        },
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
                        colors: allSectionsValid && _hasChanges
                            ? [const Color(0xFFD4AF37), const Color(0xFFB8941F)]
                            : [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: allSectionsValid && _hasChanges
                          ? [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(_glowAnimation.value),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        _hasChanges
                            ? 'Save Changes'
                            : allSectionsValid
                            ? 'No Changes'
                            : 'Complete All Sections',
                        style: TextStyle(
                          color: allSectionsValid && _hasChanges
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
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