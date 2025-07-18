import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'edit_profile_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isUploading = false;
  String? _profileImageUrl;
  String? _username;
  DateTime? _lastUsernameChange;
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _achievements = [];

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
        setState(() {
          _profileData = doc.data();
          _profileImageUrl = _profileData?['profileImageUrl'];
          _username = _profileData?['username'];
          _lastUsernameChange = (_profileData?['lastUsernameChange'] as Timestamp?)?.toDate();
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
      _showGlassMessage('Error loading profile data', isError: true);
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

  Future<void> _pickImage() async {
    try {
      // Check if image picker is available
      final bool isAvailable = await _picker.supportsImageSource(ImageSource.gallery);
      if (!isAvailable) {
        _showGlassMessage('Image picker not available on this device', isError: true);
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) {
        // User cancelled, don't show error
        return;
      }

      if (user == null) {
        _showGlassMessage('User not authenticated', isError: true);
        return;
      }

      setState(() => _isUploading = true);

      // Verify file exists and is readable
      final file = File(image.path);
      if (!await file.exists()) {
        throw Exception('Selected image file not found');
      }

      // Check file size (limit to 5MB)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image file too large (max 5MB)');
      }

      // Upload to Firebase Storage with better error handling
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user!.uid}.jpg');

      // Upload with metadata
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': user!.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final taskSnapshot = await uploadTask;
      final url = await taskSnapshot.ref.getDownloadURL();

      // Update Firestore with proper error handling
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'profileImageUrl': url,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _profileImageUrl = url;
        _isUploading = false;
      });

      HapticFeedback.mediumImpact();
      _showGlassMessage('Profile picture updated successfully');

    } catch (e) {
      setState(() => _isUploading = false);
      print('Error uploading image: $e');

      String errorMessage = 'Error uploading image';
      if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Check storage permissions.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Check your connection.';
      } else if (e.toString().contains('too large')) {
        errorMessage = 'Image file too large (max 5MB)';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Selected image file not found';
      }

      _showGlassMessage(errorMessage, isError: true);
    }
  }

  Future<bool> _isUsernameAvailable(String username) async {
    try {
      // Simple query without complex filtering
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      // If no documents found, username is available
      if (querySnapshot.docs.isEmpty) {
        return true;
      }

      // If documents found, check if any belong to a different user
      for (var doc in querySnapshot.docs) {
        if (doc.id != user!.uid) {
          return false; // Username taken by another user
        }
      }

      return true; // Username is available (or belongs to current user)
    } catch (e) {
      print('Error checking username availability: $e');
      // Instead of throwing, return false to be safe
      return false;
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    if (!canChangeUsername || user == null) {
      _showGlassMessage('Username can only be changed once every 7 days', isError: true);
      return;
    }

    try {
      // Validate username format
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

      // Check if username is available
      final isAvailable = await _isUsernameAvailable(newUsername);
      if (!isAvailable) {
        throw Exception('Username already taken');
      }

      // Update username with proper merge
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'username': newUsername,
        'lastUsernameChange': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _username = newUsername;
        _lastUsernameChange = DateTime.now();
      });

      HapticFeedback.mediumImpact();
      _showGlassMessage('Username updated successfully');
    } catch (e) {
      print('Error updating username: $e');
      _showGlassMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showGlassMessage(String message, {bool isError = false}) {
    HapticFeedback.mediumImpact();

    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 80,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isError
                          ? Colors.red.withOpacity(0.15)
                          : Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isError
                            ? Colors.red.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isError
                                ? Colors.red.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isError ? Icons.error_outline : Icons.check,
                            size: 16,
                            color: isError ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Remove the overlay after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
                  _buildSettingsSections(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
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
                    : () => _showGlassMessage(
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
                    'Start your first workout to begin earning achievements and unlock your full potential!',
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

  Widget _buildSettingsSections() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFILE SETTINGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            'Personal Information',
            'Age, Sport, Discipline',
            Icons.person_outline,
                () => _navigateToEdit('personal'),
          ),
          _buildSettingCard(
            'Fitness Goals',
            'Training objectives',
            Icons.flag_outlined,
                () => _navigateToEdit('goals'),
          ),
          _buildSettingCard(
            'Equipment',
            'Available equipment',
            Icons.fitness_center_outlined,
                () => _navigateToEdit('equipment'),
          ),
          _buildSettingCard(
            'Training Schedule',
            'Hours per week',
            Icons.schedule_outlined,
                () => _navigateToEdit('schedule'),
          ),
          _buildSettingCard(
            'Physical Condition',
            'Injuries & flexibility',
            Icons.health_and_safety_outlined,
                () => _navigateToEdit('condition'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                icon,
                color: Colors.white.withOpacity(0.7),
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

  void _navigateToEdit(String section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileSection(
          section: section,
          profileData: _profileData ?? {},
          onUpdate: () => _loadUserData(),
        ),
      ),
    );
  }
}