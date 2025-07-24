import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import 'auth_screen.dart';
import 'training_preferences_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _notificationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _notificationSlideAnimation;
  late Animation<double> _notificationFadeAnimation;

  bool _isUploading = false;
  String? _profileImageUrl;
  String? _username;
  DateTime? _lastUsernameChange;
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _achievements = [];
  bool _marketingConsent = false;
  DateTime? _marketingConsentDate;

  // For birthday tracking
  DateTime? _birthDate;
  int? _currentAge;

  // Notification state
  bool _showNotification = false;
  String _notificationMessage = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
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

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _profileData = data;
          _profileImageUrl = data?['profileImageUrl'];
          _username = data?['username'];
          _lastUsernameChange = (data?['lastUsernameChange'] as Timestamp?)?.toDate();
          _marketingConsent = data?['marketing_consent'] ?? false;
          _marketingConsentDate = (data?['marketing_consent_date'] as Timestamp?)?.toDate();

          // Load birthday and calculate age
          if (data?['birthDate'] != null) {
            _birthDate = (data!['birthDate'] as Timestamp).toDate();
            _currentAge = _calculateAge(_birthDate!);

            // Update age in profile if it's different
            final profileAge = data['profile']?['age'];
            if (profileAge != null) {
              final ageRange = _getAgeRange(_currentAge!);
              if (profileAge != ageRange) {
                _updateAgeInProfile(ageRange);
              }
            }
          }
        });
      }

      // Load achievements
      final achievementsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('achievements')
          .orderBy('earnedAt', descending: true)
          .get();

      setState(() {
        _achievements = achievementsSnap.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
      });
    } catch (e) {
      print('Error loading user data: $e');
      _showGlassyNotification('Error loading profile data', isError: true);
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _getAgeRange(int age) {
    if (age < 18) return 'Under 18';
    if (age <= 24) return '18-24';
    if (age <= 34) return '25-34';
    if (age <= 44) return '35-44';
    if (age <= 54) return '45-54';
    if (age <= 64) return '55-64';
    return '65+';
  }

  Future<void> _updateAgeInProfile(String ageRange) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'profile.age': ageRange,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating age: $e');
    }
  }

  bool get canChangeUsername {
    if (_lastUsernameChange == null) return true;
    final daysSinceLastChange = DateTime.now().difference(_lastUsernameChange!).inDays;
    return daysSinceLastChange >= 7;
  }

  int get daysUntilUsernameChange {
    if (_lastUsernameChange == null) return 0;
    final daysSinceLastChange = DateTime.now().difference(_lastUsernameChange!).inDays;
    return (7 - daysSinceLastChange).clamp(0, 7);
  }

  Future<void> _updateMarketingConsent(bool consent) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'marketing_consent': consent,
        'marketing_consent_date': consent ? FieldValue.serverTimestamp() : null,
        'updated_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _marketingConsent = consent;
        if (consent) {
          _marketingConsentDate = DateTime.now();
        }
      });

      _showGlassyNotification(
          consent
              ? 'Marketing preferences updated. You\'ll receive updates about new features and fitness tips!'
              : 'Marketing preferences updated. You\'ll no longer receive promotional emails.'
      );
    } catch (e) {
      print('Error updating marketing consent: $e');
      _showGlassyNotification('Error updating preferences', isError: true);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      if (user == null) {
        _showGlassyNotification('User not authenticated', isError: true);
        return;
      }

      setState(() => _isUploading = true);

      final file = File(image.path);

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(user!.uid)
          .child('profile.jpg');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final taskSnapshot = await uploadTask;
      final url = await taskSnapshot.ref.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'profileImageUrl': url,
        'updated_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = url;
        _isUploading = false;
      });

      HapticFeedback.mediumImpact();
      _showGlassyNotification('Profile picture updated successfully');

    } catch (e) {
      setState(() => _isUploading = false);
      print('Error uploading image: $e');
      _showGlassyNotification('Error uploading image', isError: true);
    }
  }

  Future<bool> _isUsernameAvailable(String username) async {
    try {
      // Check in usernames collection
      final usernameDoc = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      if (!usernameDoc.exists) {
        return true;
      }

      final ownerId = usernameDoc.data()?['userId'];
      return ownerId == user!.uid;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    if (!canChangeUsername || user == null) {
      _showGlassyNotification('Username can only be changed once every 7 days', isError: true);
      return;
    }

    try {
      // Validate username
      if (newUsername.isEmpty) {
        throw Exception('Username cannot be empty');
      }

      if (newUsername.length < 3) {
        throw Exception('Username must be at least 3 characters');
      }

      if (newUsername.length > 20) {
        throw Exception('Username must be less than 20 characters');
      }

      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(newUsername)) {
        throw Exception('Username can only contain letters, numbers, and underscores');
      }

      // Check availability
      final isAvailable = await _isUsernameAvailable(newUsername);
      if (!isAvailable) {
        throw Exception('Username already taken');
      }

      // Use batch write for atomic updates
      final batch = FirebaseFirestore.instance.batch();

      // Delete old username if exists
      if (_username != null && _username!.isNotEmpty) {
        final oldUsernameRef = FirebaseFirestore.instance
            .collection('usernames')
            .doc(_username!.toLowerCase());
        batch.delete(oldUsernameRef);
      }

      // Add new username
      final newUsernameRef = FirebaseFirestore.instance
          .collection('usernames')
          .doc(newUsername.toLowerCase());
      batch.set(newUsernameRef, {
        'userId': user!.uid,
        'username': newUsername,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user document
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);
      batch.update(userRef, {
        'username': newUsername,
        'lastUsernameChange': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();

      setState(() {
        _username = newUsername;
        _lastUsernameChange = DateTime.now();
      });

      HapticFeedback.mediumImpact();
      _showGlassyNotification('Username updated successfully');
    } catch (e) {
      print('Error updating username: $e');
      _showGlassyNotification(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
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

  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _sendDeleteAccountCode() async {
    try {
      final code = _generateVerificationCode();

      // Store code in Firestore - this will trigger the Cloud Function to send email
      await FirebaseFirestore.instance
          .collection('delete_requests')
          .doc(user!.uid)
          .set({
        'code': code,
        'created_at': FieldValue.serverTimestamp(),
        'email': user!.email,
      });

      _showGlassyNotification('Verification code sent to ${user!.email}');
    } catch (e) {
      print('Error sending delete account code: $e');
      _showGlassyNotification('Error sending verification code. Please try again.', isError: true);
    }
  }

  Future<void> _sendEmailChangeCode(String newEmail) async {
    try {
      final code = _generateVerificationCode();

      // Store code in Firestore - this will trigger the Cloud Function to send email
      await FirebaseFirestore.instance
          .collection('email_changes')
          .doc(user!.uid)
          .set({
        'code': code,
        'created_at': FieldValue.serverTimestamp(),
        'currentEmail': user!.email,
        'newEmail': newEmail,
      });

      _showGlassyNotification('Verification code sent to $newEmail');
    } catch (e) {
      print('Error sending email change code: $e');
      _showGlassyNotification('Error sending verification code. Please try again.', isError: true);
    }
  }

  Future<void> _verifyEmailChange(String code) async {
    try {
      // Call the Cloud Function to verify code and change email
      final callable = _functions.httpsCallable('changeEmailWithCode');
      final result = await callable.call({
        'code': code,
      });

      if (result.data['success'] == true) {
        _showGlassyNotification('Email updated successfully to ${result.data['newEmail']}');
        // Refresh user data
        await _loadUserData();
      }
    } on FirebaseFunctionsException catch (e) {
      _showGlassyNotification(e.message ?? 'Error changing email', isError: true);
    } catch (e) {
      _showGlassyNotification('Error changing email: ${e.toString()}', isError: true);
    }
  }

  Future<void> _deleteAccount(String code) async {
    try {
      // Call the Cloud Function to verify code and delete account
      final callable = _functions.httpsCallable('deleteAccountWithCode');
      final result = await callable.call({
        'code': code,
      });

      if (result.data['success'] == true) {
        // Navigate to auth screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
          );
        }
      }
    } on FirebaseFunctionsException catch (e) {
      _showGlassyNotification(e.message ?? 'Error deleting account', isError: true);
    } catch (e) {
      _showGlassyNotification('Error deleting account: ${e.toString()}', isError: true);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildProfileSection(),
                      _buildAchievementsSection(),
                      _buildTrainingPreferences(),
                      _buildAccountSettings(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
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
            onTap: () => Navigator.pop(context),
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
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'PROFILE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _profileImageUrl != null
                        ? Image.network(
                      _profileImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.white.withOpacity(0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        );
                      },
                    )
                        : Container(
                      color: Colors.white.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Username Section
          Column(
            children: [
              if (_username != null) ...[
                Text(
                  '@$_username',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              GestureDetector(
                onTap: canChangeUsername
                    ? () => _showUsernameDialog()
                    : () => _showGlassyNotification(
                  'Username can be changed in $daysUntilUsernameChange days',
                  isError: true,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: canChangeUsername
                        ? const Color(0xFFD4AF37).withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: canChangeUsername
                          ? const Color(0xFFD4AF37).withOpacity(0.4)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    canChangeUsername
                        ? (_username == null ? 'Set Username' : 'Change Username')
                        : 'Change in $daysUntilUsernameChange days',
                    style: TextStyle(
                      fontSize: 14,
                      color: canChangeUsername
                          ? const Color(0xFFD4AF37)
                          : Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'ACHIEVEMENTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD4AF37),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_achievements.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF0F0F0F),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No achievements yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your first workout to begin earning achievements!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _achievements.length,
                itemBuilder: (context, index) {
                  final achievement = _achievements[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFD4AF37),
                                const Color(0xFFB8941F),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              achievement['icon'] ?? '🏆',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          achievement['name'] ?? '',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrainingPreferences() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRAINING PREFERENCES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildPreferenceCard(
            'Equipment & Training Setup',
            'Update your equipment, sport, and training preferences',
            Icons.settings_outlined,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrainingPreferencesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCOUNT SETTINGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            'Birthday',
            _birthDate != null
                ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year} (Age: $_currentAge)'
                : 'Not set',
            Icons.cake_outlined,
                () => _showBirthdayPicker(),
          ),
          _buildSettingCard(
            'Email Address',
            user?.email ?? '',
            Icons.email_outlined,
                () => _showEmailUpdateDialog(),
          ),
          _buildSettingCard(
            'Password',
            '••••••••',
            Icons.lock_outline,
                () => _showPasswordUpdateDialog(),
          ),
          _buildMarketingConsentCard(),
          _buildSettingCard(
            'Sign Out',
            'Sign out of your account',
            Icons.logout,
                () => _showSignOutDialog(),
            isDestructive: true,
          ),
          _buildSettingCard(
            'Delete Account',
            'Permanently delete your account and all data',
            Icons.delete_forever,
                () => _showDeleteAccountDialog(),
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingConsentCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.mail_outline,
              color: Colors.white.withOpacity(0.7),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Marketing Emails',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _marketingConsent
                      ? 'Receive updates about new features and fitness tips'
                      : 'Marketing emails are disabled',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                if (_marketingConsentDate != null && _marketingConsent) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Opted in on ${_marketingConsentDate!.day}/${_marketingConsentDate!.month}/${_marketingConsentDate!.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: _marketingConsent,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              _updateMarketingConsent(value);
            },
            activeColor: const Color(0xFFD4AF37),
            inactiveThumbColor: Colors.white.withOpacity(0.3),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A00),
              const Color(0xFF2D2D00),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFD4AF37),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFFD4AF37).withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(String title, String subtitle, IconData icon, VoidCallback onTap,
      {bool isDestructive = false, bool isDanger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDanger
              ? Colors.red.withOpacity(0.05)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDanger
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDanger
                    ? Colors.red.withOpacity(0.1)
                    : isDestructive
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDanger
                    ? Colors.red.withOpacity(0.7)
                    : isDestructive
                    ? Colors.orange.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDanger
                          ? Colors.red[300]
                          : isDestructive
                          ? Colors.orange[300]
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDanger
                          ? Colors.red.withOpacity(0.5)
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showUsernameDialog() {
    final controller = TextEditingController(text: _username);

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
          'Set Username',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter username',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixText: '@',
                prefixStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                LengthLimitingTextInputFormatter(20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You can only change your username once every 7 days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
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
              final username = controller.text.trim();
              if (username.isNotEmpty) {
                Navigator.pop(context);
                _updateUsername(username);
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBirthdayPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthDate) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'birthDate': Timestamp.fromDate(picked),
          'updated_at': FieldValue.serverTimestamp(),
        });

        setState(() {
          _birthDate = picked;
          _currentAge = _calculateAge(picked);
        });

        // Update age in profile
        final ageRange = _getAgeRange(_currentAge!);
        await _updateAgeInProfile(ageRange);

        _showGlassyNotification('Birthday updated successfully');
      } catch (e) {
        _showGlassyNotification('Error updating birthday', isError: true);
      }
    }
  }

  void _showEmailUpdateDialog() {
    final controller = TextEditingController(text: user?.email);
    final codeController = TextEditingController();
    bool codeSent = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          title: const Text(
            'Update Email',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!codeSent) ...[
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter new email',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A verification code will be sent to your new email address',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: codeController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit code',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verification code sent to ${controller.text}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
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
              onPressed: () async {
                if (!codeSent) {
                  final newEmail = controller.text.trim();
                  if (newEmail.isNotEmpty && newEmail != user?.email) {
                    // Validate email format
                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(newEmail)) {
                      _showGlassyNotification('Please enter a valid email address', isError: true);
                      return;
                    }
                    await _sendEmailChangeCode(newEmail);
                    setState(() {
                      codeSent = true;
                    });
                  }
                } else {
                  final code = codeController.text.trim();
                  if (code.length == 6) {
                    Navigator.pop(context);
                    await _verifyEmailChange(code);
                  }
                }
              },
              child: Text(
                codeSent ? 'Verify' : 'Send Code',
                style: const TextStyle(color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordUpdateDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

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
          'Update Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New password',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm password',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Password must be at least 6 characters with 1 uppercase letter and 1 special symbol',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
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
            onPressed: () async {
              final newPassword = newPasswordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (newPassword != confirmPassword) {
                _showGlassyNotification('Passwords do not match', isError: true);
                return;
              }

              if (newPassword.length < 6 ||
                  !newPassword.contains(RegExp(r'[A-Z]')) ||
                  !newPassword.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                _showGlassyNotification('Password does not meet requirements', isError: true);
                return;
              }

              Navigator.pop(context);

              try {
                await user!.updatePassword(newPassword);
                _showGlassyNotification('Password updated successfully');
              } catch (e) {
                _showGlassyNotification('Error updating password. You may need to sign in again.', isError: true);
              }
            },
            child: const Text(
              'Update',
              style: TextStyle(color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
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
          'Sign Out',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
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
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                );
              }
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: Colors.orange[300]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final codeController = TextEditingController();
    bool codeSent = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.red.withOpacity(0.3),
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red[300],
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              if (codeSent) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: codeController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit code',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A verification code was sent to ${user?.email}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
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
              onPressed: () async {
                if (!codeSent) {
                  await _sendDeleteAccountCode();
                  setState(() {
                    codeSent = true;
                  });
                } else {
                  final code = codeController.text.trim();
                  if (code.length == 6) {
                    Navigator.pop(context);
                    await _deleteAccount(code);
                  }
                }
              },
              child: Text(
                codeSent ? 'Delete Account' : 'Send Code',
                style: TextStyle(color: Colors.red[300]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}