import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';
// import 'package:peakfit_frontend/screens/workout_generation_screen.dart';

class WhoopConnectScreen extends StatefulWidget {
  const WhoopConnectScreen({super.key});
  @override
  State<WhoopConnectScreen> createState() => _WhoopConnectScreenState();
}

class _WhoopConnectScreenState extends State<WhoopConnectScreen> {
  bool _isConnecting = false;
  StreamSubscription? _linkSubscription;
  
  // Replace with your actual Whoop client ID
  static const String _clientId = 'YOUR_WHOOP_CLIENT_ID';
  static const String _redirectUri = 'peakfit://whoop-callback';
  static const String _scope = 'read:recovery read:cycles read:workout read:sleep read:profile read:body_measurement';
  
  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }
  
  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
  
  // Listen for deep links
  void _initDeepLinkListener() {
    _linkSubscription = linkStream.listen((String? link) async {
      if (link != null && link.contains('whoop-callback')) {
        final uri = Uri.parse(link);
        final code = uri.queryParameters['code'];
        
        if (code != null) {
          await _exchangeCodeForToken(code);
        }
      }
    });
  }
  
  // Start OAuth flow
  Future<void> _connectWhoop() async {
    setState(() => _isConnecting = true);
    
    final authUrl = Uri.https('api.whoop.com', '/oauth/oauth2/auth', {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'scope': _scope,
      'state': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    
    try {
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open Whoop authorization page');
      }
    } catch (e) {
      _showError('Error launching authorization: $e');
    }
  }
  
  // Exchange authorization code for tokens
  Future<void> _exchangeCodeForToken(String code) async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions
          .httpsCallable('whoopTokenExchange')
          .call({'code': code});
      
      if (result.data['success'] == true) {
        if (!mounted) return;
        _navigateToNextScreen();
      } else {
        _showError('Failed to connect Whoop account');
      }
    } catch (e) {
      _showError('Error connecting: $e');
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }
  
  void _navigateToNextScreen() {
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => const WorkoutGenerationScreen()),
    // );
  }
  
  void _skipWhoop() {
    _navigateToNextScreen();
  }
  
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
    setState(() => _isConnecting = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
          color: Colors.black,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Whoop logo placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'W',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Connect Your Whoop',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Sync your recovery data to generate\npersonalized workouts based on your\nbody\'s readiness',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8E8E93),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Benefits list
              _BenefitRow(
                icon: Icons.favorite,
                title: 'Recovery-Based Training',
                subtitle: 'Workouts that match your body\'s readiness',
              ),
              const SizedBox(height: 24),
              _BenefitRow(
                icon: Icons.insights,
                title: 'Smart Intensity',
                subtitle: 'Automatically adjust workout intensity',
              ),
              const SizedBox(height: 24),
              _BenefitRow(
                icon: Icons.trending_up,
                title: 'Optimize Performance',
                subtitle: 'Train smarter, not harder',
              ),
              
              const Spacer(),
              
              // Connect button
              TextButton(
                onPressed: _isConnecting ? null : _connectWhoop,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Connect Whoop',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
              ),
              
              const SizedBox(height: 12),
              
              // Skip button
              TextButton(
                onPressed: _isConnecting ? null : _skipWhoop,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8E8E93),
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.black,
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
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}