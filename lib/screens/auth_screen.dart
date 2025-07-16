import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';
import 'questionnaire/questionnaire_screen.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _verificationCodeC = TextEditingController();
  bool _loading = false;
  String _msg = '';
  bool _isLogin = true;
  bool _showVerification = false;
  bool _agreeToUpdates = false;
  String? _actualVerificationCode;

  // Video controller
  late VideoPlayerController _videoController;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize video
    _videoController = VideoPlayerController.asset('assets/videos/skate-montage2.mp4')
      ..initialize().then((_) {
        _videoController.play();
        _videoController.setLooping(true);
        setState(() {});
      });

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    _verificationCodeC.dispose();
    _videoController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _sendVerificationEmail() async {
    _actualVerificationCode = _generateVerificationCode();

    // Store verification code in Firestore
    await FirebaseFirestore.instance
        .collection('verifications')
        .doc(_emailC.text.trim())
        .set({
      'code': _actualVerificationCode,
      'created_at': FieldValue.serverTimestamp(),
      'email': _emailC.text.trim(),
    });

    // The cloud function will log this code
    // In production, it would send an actual email
    if (mounted) {
      debugPrint('Verification code: $_actualVerificationCode');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to ${_emailC.text.trim()}'),
          backgroundColor: Colors.green.withOpacity(0.8),
        ),
      );
    }
  }

  Future<bool> _verifyCode() async {
    final doc = await FirebaseFirestore.instance
        .collection('verifications')
        .doc(_emailC.text.trim())
        .get();

    if (doc.exists) {
      final data = doc.data();
      return data?['code'] == _verificationCodeC.text.trim();
    }
    return false;
  }

  Future<bool> _checkQuestionnaireStatus(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['questionnaire_completed'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking questionnaire status: $e');
      return false;
    }
  }

  Future<void> _authAction() async {
    if (_showVerification) {
      // Handle verification
      if (_verificationCodeC.text.isEmpty) {
        setState(() => _msg = 'Enter verification code');
        return;
      }

      setState(() => _loading = true);

      final isValid = await _verifyCode();
      if (!isValid) {
        setState(() {
          _msg = 'Invalid verification code';
          _loading = false;
        });
        return;
      }

      // Code is valid, create account
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailC.text.trim(),
          password: _passC.text.trim(),
        );

        // Create user document with marketing consent
        final user = credential.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'created_at': FieldValue.serverTimestamp(),
            'questionnaire_completed': false,
            'email_verified': true,
            'marketing_consent': _agreeToUpdates,
            'marketing_consent_date': _agreeToUpdates ? FieldValue.serverTimestamp() : null,
          });

          // Clean up verification code
          await FirebaseFirestore.instance
              .collection('verifications')
              .doc(_emailC.text.trim())
              .delete();
        }

        _msg = 'Welcome to PeakFit';

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  QuestionnaireScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeOutExpo;

                var tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _msg = 'Error creating account';
          _loading = false;
        });
      }
      return;
    }

    if (_emailC.text.trim().isEmpty || _passC.text.isEmpty) {
      setState(() => _msg = 'Fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _msg = '';
    });

    try {
      if (!_isLogin) {
        // Sign Up - Send verification email first
        await _sendVerificationEmail();
        setState(() {
          _showVerification = true;
          _loading = false;
          _msg = 'Enter the 6-digit code sent to your email';
        });
      } else {
        // Sign In
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailC.text.trim(),
          password: _passC.text.trim(),
        );

        final isQuestionnaireCompleted = await _checkQuestionnaireStatus(credential.user!.uid);

        if (!isQuestionnaireCompleted) {
          _msg = 'Please complete your profile';

          if (mounted) {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));

            if (mounted) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      QuestionnaireScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutExpo;

                    var tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: curve),
                    );

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            }
          }
        } else {
          _msg = 'Welcome back';

          if (mounted) {
            setState(() {});
            await Future.delayed(const Duration(seconds: 1));

            if (mounted) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                  const HomeScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 600),
                ),
              );
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _msg = 'Email already registered';
          break;
        case 'weak-password':
          _msg = 'Password too weak';
          break;
        case 'user-not-found':
        case 'wrong-password':
          _msg = 'Invalid credentials';
          break;
        default:
          _msg = 'Something went wrong';
      }
    } catch (e) {
      _msg = 'Error occurred';
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email to receive a password reset link',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter your email')),
                );
                return;
              }

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: emailController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset email sent'),
                    backgroundColor: Colors.green.withOpacity(0.8),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error sending reset email'),
                    backgroundColor: Colors.red.withOpacity(0.8),
                  ),
                );
              }
            },
            child: Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video Background
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),

          // Dark overlay
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Logo/Title
                      _buildLogo(),

                      const SizedBox(height: 60),

                      // Auth Form or Verification Form
                      _showVerification ? _buildVerificationForm() : _buildAuthForm(),

                      const SizedBox(height: 20),

                      // Forgot Password (only for login)
                      if (_isLogin && !_showVerification)
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Toggle Login/Signup
                      if (!_showVerification) _buildAuthToggle(),

                      const Spacer(flex: 3),

                      // Message
                      if (_msg.isNotEmpty) _buildMessage(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Text(
          'PEAKFIT',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w200,
            letterSpacing: 8,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 20,
                color: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 120,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ELITE FITNESS',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 4,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
            Colors.white.withOpacity(0.1),
            BlendMode.overlay,
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                _buildTextField(
                  controller: _emailC,
                  hint: 'Email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passC,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 20),
                  _buildMarketingCheckbox(),
                ],
                const SizedBox(height: 40),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
            Colors.white.withOpacity(0.1),
            BlendMode.overlay,
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: Colors.white.withOpacity(0.7),
                  size: 48,
                ),
                const SizedBox(height: 20),
                Text(
                  'Verification Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter the 6-digit code sent to\n${_emailC.text.trim()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  controller: _verificationCodeC,
                  hint: '000000',
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 30),
                _buildActionButton(),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    await _sendVerificationEmail();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('New code sent'),
                        backgroundColor: Colors.green.withOpacity(0.8),
                      ),
                    );
                  },
                  child: Text(
                    'Resend Code',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketingCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToUpdates,
            onChanged: (value) {
              setState(() {
                _agreeToUpdates = value ?? false;
              });
            },
            fillColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.white.withOpacity(0.8);
              }
              return Colors.transparent;
            }),
            checkColor: Colors.black,
            side: BorderSide(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'I agree to receive updates and tips from PeakFit',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        cursorColor: Colors.white,
        cursorWidth: 2.5,
        cursorRadius: const Radius.circular(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(_glowAnimation.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _loading ? null : _authAction,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    _showVerification
                        ? 'VERIFY & CREATE ACCOUNT'
                        : (_isLogin ? 'SIGN IN' : 'CONTINUE'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account?" : "Already have an account?",
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
              _msg = '';
            });
          },
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    final isError = _msg.contains('wrong') ||
        _msg.contains('Invalid') ||
        _msg.contains('Error') ||
        _msg.contains('weak') ||
        _msg.contains('Fill');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Text(
        _msg,
        style: TextStyle(
          color: isError ? Colors.red[300] : Colors.green[300],
          fontSize: 14,
        ),
      ),
    );
  }
}