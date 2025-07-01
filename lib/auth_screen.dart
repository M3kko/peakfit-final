import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailC = TextEditingController();
  final _passC  = TextEditingController();
  bool _loading = false;
  String _msg   = '';

  /* ----------------------------- cleanup ---------------------------------- */
  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  /* ---------------------------- helpers ----------------------------------- */
  Future<void> _signUp() async => _authAction(isSignUp: true);
  Future<void> _signIn() async => _authAction(isSignUp: false);

  Future<void> _authAction({required bool isSignUp}) async {
    if (_emailC.text.trim().isEmpty || _passC.text.isEmpty) {
      setState(() => _msg = 'Email and password can’t be empty');
      return;
    }

    setState(() {
      _loading = true;
      _msg = '';
    });

    try {
      if (isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailC.text.trim(),
          password: _passC.text.trim(),
        );
        _msg = 'Account created – you’re in!';
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailC.text.trim(),
          password: _passC.text.trim(),
        );
        _msg = 'Welcome back!';
      }
      // 👉  Send the user onward, e.g. Navigator.pushReplacementNamed(...)
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _msg = 'That email is already registered.';
          break;
        case 'weak-password':
          _msg = 'Password should be at least 6 characters.';
          break;
        case 'user-not-found':
        case 'wrong-password':
          _msg = 'Invalid email or password.';
          break;
        default:
          _msg = 'Auth error: ${e.code}';
      }
    } catch (e) {
      _msg = 'Unexpected error: $e';
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  /* -------------------------------- UI ------------------------------------ */
  @override
  Widget build(BuildContext context) {
    final isDisabled = _loading;
    return Scaffold(
      appBar: AppBar(title: const Text('PeakFit Auth')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AbsorbPointer(
          absorbing: isDisabled,
          child: Column(
            children: [
              TextField(
                controller: _emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passC,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isDisabled ? null : _signUp,
                      child: const Text('Sign Up'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isDisabled ? null : _signIn,
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading) const CircularProgressIndicator(),
              if (_msg.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _msg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _msg.startsWith('Auth error') ||
                          _msg.startsWith('Invalid') ||
                          _msg.startsWith('Unexpected')
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
