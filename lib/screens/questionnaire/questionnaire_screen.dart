import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../weekly_plan_screen.dart'; // Changed from workout_screen.dart
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

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  // Store all questionnaire responses
  Map<String, dynamic> _responses = {};

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitQuestionnaire();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
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

        // navigate to weekly plan screen to show their personalized plan
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WeeklyPlanScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Profile'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / 7,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
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
          ),
          // Navigation buttons
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  child: Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(_currentPage == 6 ? 'Submit' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}