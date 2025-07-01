import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/questionnaire/questionnaire_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PeakFit',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: const AuthScreen(),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _loading = false;

  Future<void> _signUp() async {
    if (_email.text.trim().isEmpty || _pw.text.isEmpty) {
      _showMessage('Email & password required');
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pw.text.trim(),
      );
      _navigateNext();
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Signup failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    if (_email.text.trim().isEmpty || _pw.text.isEmpty) {
      _showMessage('Email & password required');
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pw.text.trim(),
      );
      _navigateNext();
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateNext() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const QuestionnaireScreen()),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PeakFit Auth'), centerTitle: true),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pw,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signUp,
                    child: const Text('Sign Up'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
          ],
        ),
      ),
    ),
  );
}
