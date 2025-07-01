import 'package:flutter/material.dart';

class Day28WorkoutScreen extends StatefulWidget {
  @override
  _Day28WorkoutScreenState createState() => _Day28WorkoutScreenState();
}

class _Day28WorkoutScreenState extends State<Day28WorkoutScreen> {
  final List<Map<String, dynamic>> exercises = [
    {
      'name': 'Single-Leg Box Step-Ups',
      'sets': 4,
      'reps': '6',
      'type': 'each',
      'icon': Icons.stairs,
      'muscle_groups': ['Glutes', 'Quads', 'Balance'],
    },
    {
      'name': 'Plyo Push-ups',
      'sets': 5,
      'reps': '5',
      'type': 'reps',
      'icon': Icons.bolt,
      'muscle_groups': ['Chest', 'Power', 'Core'],
    },
    {
      'name': 'Broad Jump to Backpedal',
      'sets': 6,
      'reps': '3',
      'type': 'reps',
      'icon': Icons.sports_basketball,
      'muscle_groups': ['Legs', 'Power', 'Agility'],
    },
    {
      'name': 'Single-Leg RDL to Jump',
      'sets': 4,
      'reps': '4',
      'type': 'each',
      'icon': Icons.flight_takeoff,
      'muscle_groups': ['Hamstrings', 'Glutes', 'Explosive'],
    },
    {
      'name': 'Depth Drops',
      'sets': 5,
      'reps': '3',
      'type': 'reps',
      'icon': Icons.arrow_downward,
      'muscle_groups': ['Reactive', 'Calves', 'Power'],
    },
    {
      'name': 'Pogo Jumps',
      'sets': 3,
      'reps': '15',
      'type': 'reps',
      'icon': Icons.upload,
      'muscle_groups': ['Calves', 'Elasticity', 'Rhythm'],
    },
    {
      'name': 'Band-Resisted Lateral Bounds',
      'sets': 3,
      'reps': '6',
      'type': 'each',
      'icon': Icons.swap_horiz,
      'muscle_groups': ['Hips', 'Lateral Power', 'Basketball'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Main scrollable content
            ListView(
              padding: EdgeInsets.only(bottom: 100), // Space for floating button
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Color(0xFF2D3436)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 16
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'AI Optimized',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Vertical Jump Specialized",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.timer, color: Color(0xFF636E72), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Est. 35-40 minutes',
                            style: TextStyle(
                              color: Color(0xFF636E72),
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(Icons.fitness_center, color: Color(0xFF636E72), size: 20),
                          SizedBox(width: 8),
                          Text(
                            '7 exercises',
                            style: TextStyle(
                              color: Color(0xFF636E72),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // AI Insights Box
                Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF667EEA).withOpacity(0.1),
                        Color(0xFF764BA2).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF667EEA).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insights,
                        color: Color(0xFF667EEA),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fully personalized for your needs',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                            Text(
                              'Focus: Glute activation, single-leg stability, explosive power',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF636E72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Exercise List
                ...exercises.map((exercise) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFF667EEA).withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF667EEA).withOpacity(0.08),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Exercise Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF667EEA).withOpacity(0.1),
                                  Color(0xFF764BA2).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              exercise['icon'],
                              color: Color(0xFF667EEA),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),

                          // Exercise Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3436),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${exercise['sets']} sets × ${exercise['reps']} ${exercise['type']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF636E72),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: (exercise['muscle_groups'] as List).map((muscle) {
                                    return Container(
                                      margin: EdgeInsets.only(right: 6),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF667EEA).withOpacity(0.1),
                                            Color(0xFF764BA2).withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        muscle,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF667EEA),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          // Info Icon
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFB2BEC3),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                // Progress Note
                Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Color(0xFF667EEA),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your workouts have evolved based on 28 days of data',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D3436),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Add some spacing at the bottom
                SizedBox(height: 20),
              ],
            ),

            // Floating Start Button at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF8F9FA).withOpacity(0.0),
                      Color(0xFFF8F9FA).withOpacity(0.9),
                      Color(0xFFF8F9FA),
                    ],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to workout timer/tracker screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2D3436),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Start Workout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}