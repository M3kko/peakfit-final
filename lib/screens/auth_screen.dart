import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  final _resetCodeC = TextEditingController();
  final _newPasswordC = TextEditingController();
  bool _loading = false;
  String _msg = '';
  bool _isLogin = true;
  bool _showVerification = false;
  bool _showPasswordReset = false;
  bool _agreeToUpdates = false;
  String? _actualVerificationCode;
  String? _resetEmail;

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

    // Add listeners for password validation
    _newPasswordC.addListener(() {
      setState(() {
        // Just trigger rebuild to update button state
      });
    });
    _resetCodeC.addListener(() {
      setState(() {
        // Just trigger rebuild to update button state
      });
    });
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    _verificationCodeC.dispose();
    _resetCodeC.dispose();
    _newPasswordC.dispose();
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

  // Custom method to show glassy error/success messages
  void _showGlassySnackBar(String message, bool isError) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isError
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isError
                  ? Colors.red.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red[300] : Colors.green[300],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError ? Colors.red[300] : Colors.green[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  bool _isPasswordValid(String password) {
    if (password.length < 6) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  String _getPasswordRequirements(String password) {
    List<String> missing = [];
    if (password.length < 6) missing.add('at least 6 characters');
    if (!password.contains(RegExp(r'[A-Z]'))) missing.add('an uppercase letter');
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) missing.add('a special symbol');

    if (missing.isEmpty) return '';
    return 'Password must contain ${missing.join(', ')}';
  }

  Future<void> _sendVerificationEmail() async {
    final email = _emailC.text.trim().toLowerCase();

    // Delete any existing verification codes for this email
    await FirebaseFirestore.instance
        .collection('verifications')
        .doc(email)
        .delete();

    _actualVerificationCode = _generateVerificationCode();

    // Store new verification code
    await FirebaseFirestore.instance
        .collection('verifications')
        .doc(email)
        .set({
      'code': _actualVerificationCode,
      'created_at': FieldValue.serverTimestamp(),
      'email': email,
    });

    // The cloud function will log this code
    // In production, it would send an actual email
    if (mounted) {
      debugPrint('Verification code: $_actualVerificationCode');
      _showGlassySnackBar('Verification code sent to $email', false);
    }
  }

  Future<bool> _verifyCode() async {
    final email = _emailC.text.trim().toLowerCase();
    final doc = await FirebaseFirestore.instance
        .collection('verifications')
        .doc(email)
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

  Future<bool> _checkEmailExists(String email) async {
    try {
      // Normalize email
      final normalizedEmail = email.trim().toLowerCase();
      // Check in the user_emails collection (more secure approach)
      final doc = await FirebaseFirestore.instance
          .collection('user_emails')
          .doc(normalizedEmail)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking email existence: $e');
      // Fallback: try checking in users collection
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        return querySnapshot.docs.isNotEmpty;
      } catch (e2) {
        print('Fallback error checking email: $e2');
        return false;
      }
    }
  }

  Future<void> _authAction() async {
    final email = _emailC.text.trim().toLowerCase();
    final password = _passC.text.trim();

    if (_showVerification) {
      // Handle verification
      if (_verificationCodeC.text.trim().isEmpty) {
        setState(() => _msg = 'Please enter the verification code');
        return;
      }

      setState(() => _loading = true);

      final isValid = await _verifyCode();
      if (!isValid) {
        setState(() {
          _msg = 'Invalid verification code. Please try again.';
          _loading = false;
        });
        return;
      }

      // Code is valid, create account
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Create user document with ONLY the required fields
        final user = credential.user;
        if (user != null) {
          // First, create with only required fields
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'created_at': FieldValue.serverTimestamp(),
          });

          // Then update with additional fields
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'questionnaire_completed': false,
            'email_verified': true,
            'marketing_consent': _agreeToUpdates,
            'marketing_consent_date': _agreeToUpdates ? FieldValue.serverTimestamp() : null,
          });

          // Also create entry in user_emails collection for future email lookups
          await FirebaseFirestore.instance
              .collection('user_emails')
              .doc(email)
              .set({
            'uid': user.uid,
            'created_at': FieldValue.serverTimestamp(),
          });

          // Clean up verification code
          await FirebaseFirestore.instance
              .collection('verifications')
              .doc(email)
              .delete();
        }

        _msg = 'Welcome to PeakFit!';

        if (mounted) {
          // Clear any snackbars before navigation
          ScaffoldMessenger.of(context).clearSnackBars();

          // Wait for animations to complete
          await Future.delayed(const Duration(milliseconds: 1500));

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
          _msg = 'Failed to create account. Please try again.';
          _loading = false;
        });
      }
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      setState(() => _msg = 'Please fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _msg = '';
    });

    try {
      if (!_isLogin) {
        // Sign Up - Check if email already exists
        try {
          // First check Firebase Auth
          final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
          if (methods.isNotEmpty) {
            setState(() {
              _msg = 'This email is already registered. Please sign in instead.';
              _loading = false;
            });
            return;
          }

          // Also check Firestore to be sure
          final emailExists = await _checkEmailExists(email);
          if (emailExists) {
            setState(() {
              _msg = 'This email is already registered. Please sign in instead.';
              _loading = false;
            });
            return;
          }

          // Send verification email
          await _sendVerificationEmail();
          setState(() {
            _showVerification = true;
            _loading = false;
            _msg = 'Enter the 6-digit code sent to your email';
          });
        } catch (e) {
          print('Sign up error: $e');
          setState(() {
            _msg = 'An error occurred. Please try again.';
            _loading = false;
          });
        }
      } else {
        // Sign In
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final isQuestionnaireCompleted = await _checkQuestionnaireStatus(credential.user!.uid);

        if (!isQuestionnaireCompleted) {
          _msg = 'Welcome back! Please complete your profile.';

          if (mounted) {
            setState(() {});

            // Clear any snackbars before navigation
            ScaffoldMessenger.of(context).clearSnackBars();

            await Future.delayed(const Duration(milliseconds: 1500));

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
          _msg = 'Welcome back to PeakFit!';

          if (mounted) {
            setState(() {});

            // Clear any snackbars before navigation
            ScaffoldMessenger.of(context).clearSnackBars();

            await Future.delayed(const Duration(milliseconds: 1500));

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
          _msg = 'This email is already registered. Please sign in instead.';
          break;
        case 'weak-password':
          _msg = 'Password should be at least 6 characters long.';
          break;
        case 'user-not-found':
          _msg = 'No account found with this email. Please sign up first.';
          break;
        case 'wrong-password':
          _msg = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          _msg = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          _msg = 'Too many failed attempts. Please try again later.';
          break;
        default:
          _msg = 'An error occurred. Please try again.';
      }
    } catch (e) {
      print('Auth error: $e');
      _msg = 'An unexpected error occurred. Please try again.';
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _showForgotPasswordDialog() {
    setState(() {
      _showPasswordReset = true;
      _resetEmail = '';
      _resetCodeC.clear();
      _newPasswordC.clear();
      _msg = '';
    });
  }

  Future<void> _sendPasswordResetCode() async {
    final email = _emailC.text.trim().toLowerCase();

    if (email.isEmpty) {
      setState(() => _msg = 'Please enter your email address');
      return;
    }

    setState(() => _loading = true);

    try {
      // Check if email exists in the system
      final emailExists = await _checkEmailExists(email);
      if (!emailExists) {
        setState(() {
          _msg = 'No account found with this email address';
          _loading = false;
        });
        return;
      }

      // Delete any existing password reset codes for this email
      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(email)
          .delete();

      // Generate and store new reset code
      final resetCode = _generateVerificationCode();

      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(email)
          .set({
        'code': resetCode,
        'created_at': FieldValue.serverTimestamp(),
        'email': email,
      });

      // In production, send email here
      debugPrint('Password reset code: $resetCode');

      setState(() {
        _resetEmail = email;
        _loading = false;
        _msg = 'Reset code sent to $email';
      });

      _showGlassySnackBar('Reset code sent to $email', false);
    } catch (e) {
      setState(() {
        _msg = 'Failed to send reset code. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_resetCodeC.text.trim().isEmpty) {
      setState(() => _msg = 'Please enter the reset code');
      return;
    }

    if (!_isPasswordValid(_newPasswordC.text.trim())) {
      setState(() => _msg = _getPasswordRequirements(_newPasswordC.text.trim()));
      return;
    }

    setState(() => _loading = true);

    try {
      // Call the Cloud Function to reset password
      final functions = FirebaseFunctions.instance;
      final result = await functions
          .httpsCallable('resetPasswordWithCode')
          .call({
        'email': _resetEmail,
        'code': _resetCodeC.text.trim(),
        'newPassword': _newPasswordC.text.trim(),
      });

      if (result.data['success'] == true) {
        // Delete the used reset code
        await FirebaseFirestore.instance
            .collection('password_resets')
            .doc(_resetEmail!)
            .delete();

        _msg = 'Password reset successfully!';
        _showGlassySnackBar('Password reset successfully! You can now sign in.', false);

        if (mounted) {
          // Clear any snackbars before navigation
          ScaffoldMessenger.of(context).clearSnackBars();

          await Future.delayed(const Duration(milliseconds: 1500));

          setState(() {
            _showPasswordReset = false;
            _isLogin = true;
            _resetCodeC.clear();
            _newPasswordC.clear();
            _msg = '';
          });
        }
      } else {
        throw Exception('Password reset failed');
      }
    } catch (e) {
      setState(() {
        _msg = 'Invalid reset code or error occurred';
        _loading = false;
      });
    }
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
                    children: [
                      const Spacer(flex: 1),

                      // Logo/Title
                      _buildLogo(),

                      const SizedBox(height: 40),

                      // Auth Form or Verification Form
                      _showVerification
                          ? _buildVerificationForm()
                          : (_showPasswordReset
                          ? _buildPasswordResetForm()
                          : _buildAuthForm()),

                      const SizedBox(height: 16),

                      // Forgot Password (only for login)
                      if (_isLogin && !_showVerification && !_showPasswordReset)
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

                      const SizedBox(height: 12),

                      // Toggle Login/Signup or Back button
                      if (!_showVerification && !_showPasswordReset)
                        _buildAuthToggle()
                      else if (_showPasswordReset && (_resetEmail == null || _resetEmail!.isEmpty))
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showPasswordReset = false;
                              _msg = '';
                            });
                          },
                          child: Text(
                            'Back to Login',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),

                      const Spacer(flex: 2),

                      // Message
                      if (_msg.isNotEmpty) ...[
                        _buildMessage(),
                        const SizedBox(height: 20),
                      ],
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
            padding: const EdgeInsets.all(24),
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
                    _showGlassySnackBar('New verification code sent', false);
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

  Widget _buildPasswordResetForm() {
    final bool canResetPassword = _resetCodeC.text.trim().length == 6 &&
        _isPasswordValid(_newPasswordC.text.trim());

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
                  Icons.lock_reset,
                  color: Colors.white.withOpacity(0.7),
                  size: 48,
                ),
                const SizedBox(height: 20),
                Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 10),

                if (_resetEmail == null || _resetEmail!.isEmpty) ...[
                  Text(
                    'Enter your email to receive a reset code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    controller: _emailC,
                    hint: 'Email',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 30),
                  _buildPasswordResetButton(true),
                ] else ...[
                  Text(
                    'Enter the 6-digit code sent to\n$_resetEmail',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    controller: _resetCodeC,
                    hint: '000000',
                    icon: Icons.lock_outline,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _newPasswordC,
                    hint: 'New Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Password must contain at least 6 characters,\nan uppercase letter, and a special symbol',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildPasswordResetButton(false, canResetPassword),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      await _sendPasswordResetCode();
                      _showGlassySnackBar('New reset code sent', false);
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordResetButton(bool isSendCode, [bool enabled = true]) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: enabled ? [
              BoxShadow(
                color: Colors.white.withOpacity(_glowAnimation.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ] : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _loading ? null : () {
                if (isSendCode) {
                  _sendPasswordResetCode();
                } else {
                  if (!enabled) {
                    setState(() => _msg = _getPasswordRequirements(_newPasswordC.text.trim()));
                  } else {
                    _resetPassword();
                  }
                }
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: enabled ? [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ] : [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    isSendCode ? 'SEND RESET CODE' : 'RESET PASSWORD',
                    style: TextStyle(
                      color: enabled ? Colors.black : Colors.black.withOpacity(0.5),
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
              _showVerification = false;
              _verificationCodeC.clear();
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
    final isError = _msg.toLowerCase().contains('error') ||
        _msg.toLowerCase().contains('invalid') ||
        _msg.toLowerCase().contains('incorrect') ||
        _msg.toLowerCase().contains('failed') ||
        _msg.toLowerCase().contains('wrong') ||
        _msg.toLowerCase().contains('weak') ||
        _msg.toLowerCase().contains('fill') ||
        _msg.toLowerCase().contains('no account') ||
        _msg.toLowerCase().contains('already');

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