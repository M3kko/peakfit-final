import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _workout;
  String _message = '';

  /* --------------------------- lifecycle / debug -------------------------- */
  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _checkUserProfile();
    _checkExercises();
  }

  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _message = user == null
          ? 'User not authenticated. Please log in again.'
          : 'Ready to generate workout for ${user.email}';
    });
  }

  Future<void> _checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    debugPrint('User profile exists? ${doc.exists}');
  }

  Future<void> _checkExercises() async {
    final snap =
    await FirebaseFirestore.instance.collection('exercises').get();
    debugPrint('Exercises in DB: ${snap.docs.length}');
  }

  /* ----------------------- generate workout (no payload) ------------------- */
  Future<void> _generateWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _message = 'You’ve been signed out – log in again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
      _workout = null;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('generatePersonalizedWorkout');

      final res = await callable.call(); // 👈 no body needed
      setState(() {
        _workout = Map<String, dynamic>.from(res.data['workout']);
        _message = 'Workout generated!';
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() => _message = 'Error: ${e.message}');
      debugPrint('${e.code} – ${e.details}');
    } catch (e) {
      setState(() => _message = 'Unexpected error: $e');
      debugPrint('Unexpected: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /* ---------------------------------- UI ---------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Workout'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _generateWorkout,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Generate Workout'),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _message.startsWith('Error') ? Colors.red : Colors.green,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (_workout != null) ...[
              Text(
                _workout!['name'],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('Duration: ${_workout!['estimated_duration']} minutes'),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _workout!['exercises'].length,
                  itemBuilder: (context, i) {
                    final ex = _workout!['exercises'][i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          ex['name'] ?? ex['Name'] ?? 'Exercise',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${ex['sets']} sets × ${ex['reps']} reps'),
                            if (ex['category'] != null)
                              Text('Category: ${ex['category']}'),
                            if (ex['muscle_groups'] != null)
                              Text('Muscles: ${ex['muscle_groups'].join(', ')}'),
                          ],
                        ),
                        trailing: Text('Rest: ${ex['rest']}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
