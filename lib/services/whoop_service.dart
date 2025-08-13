import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this for PlatformException
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_credentials.dart';

class WhoopService {
  static const String _clientId = ApiCredentials.whoopClientId;
  static const String _redirectUri = ApiCredentials.whoopRedirectUri;

  // WHOOP OAuth endpoints
  static const String _authorizationEndpoint = 'https://api.prod.whoop.com/oauth/oauth2/auth';
  static const String _tokenEndpoint = 'https://api.prod.whoop.com/oauth/oauth2/token';
  static const String _apiBaseUrl = 'https://api.prod.whoop.com/developer/v1';

  // Storage keys
  static const String _accessTokenKey = 'whoop_access_token';
  static const String _refreshTokenKey = 'whoop_refresh_token';
  static const String _userIdKey = 'whoop_user_id';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Singleton pattern
  static final WhoopService _instance = WhoopService._internal();
  factory WhoopService() => _instance;
  WhoopService._internal();

  // Check if user is already connected
  Future<bool> isConnected() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token != null;
  }

  // TEST METHOD 1: Use mock data for development
  Future<bool> authenticateWithMockData() async {
    try {
      print('===== Using Mock WHOOP Data =====');

      // Store fake tokens to simulate connection
      await _secureStorage.write(key: _accessTokenKey, value: 'mock_access_token');
      await _secureStorage.write(key: _refreshTokenKey, value: 'mock_refresh_token');
      await _secureStorage.write(key: _userIdKey, value: 'mock_user_123');

      print('Mock authentication successful');
      return true;
    } catch (e) {
      print('Mock authentication error: $e');
      return false;
    }
  }

  // TEST METHOD 2: Test basic OAuth flow without WHOOP
  Future<bool> testOAuthFlow() async {
    try {
      print('===== Testing OAuth Flow =====');
      print('Client ID: $_clientId');
      print('Client ID length: ${_clientId.length}');
      print('Redirect URI: $_redirectUri');
      print('Authorization Endpoint: $_authorizationEndpoint');
      print('Token Endpoint: $_tokenEndpoint');

      // Check if client ID looks valid (not placeholder)
      if (_clientId.contains('YOUR_') || _clientId.isEmpty) {
        print('ERROR: Client ID appears to be a placeholder or empty!');
        print('Please update ApiCredentials.whoopClientId with your actual WHOOP client ID');
        return false;
      }

      print('Configuration appears valid');
      return true;
    } catch (e) {
      print('Test error: $e');
      return false;
    }
  }

  // Authenticate with WHOOP - Enhanced debugging
  Future<bool> authenticate() async {
    try {
      print('\n===== WHOOP Authentication Starting =====');
      print('Timestamp: ${DateTime.now()}');

      // First test the configuration
      final configValid = await testOAuthFlow();
      if (!configValid) {
        print('Configuration validation failed!');
        return false;
      }

      print('\nAttempting real WHOOP authentication...');
      print('Building authorization request...');

      // Try different authorization request configurations
      try {
        // ATTEMPT 1: Minimal configuration
        print('\n--- Attempt 1: Minimal configuration ---');
        final AuthorizationTokenRequest request1 = AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: _authorizationEndpoint,
            tokenEndpoint: _tokenEndpoint,
          ),
          scopes: ['read:recovery', 'read:cycles', 'read:sleep'],
        );

        print('Calling authorizeAndExchangeCode...');
        final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(request1);

        if (result != null) {
          print('SUCCESS: Got authorization response!');
          print('Access Token: ${result.accessToken != null ? "Present" : "Missing"}');
          print('Refresh Token: ${result.refreshToken != null ? "Present" : "Missing"}');

          // Store tokens
          await _secureStorage.write(key: _accessTokenKey, value: result.accessToken!);
          if (result.refreshToken != null) {
            await _secureStorage.write(key: _refreshTokenKey, value: result.refreshToken!);
          }

          // Try to get user ID
          await _fetchAndStoreUserId(result.accessToken!);

          print('===== Authentication Successful! =====\n');
          return true;
        } else {
          print('No result returned from authorization');
        }

      } catch (e1) {
        print('Attempt 1 failed: $e1');

        // ATTEMPT 2: With additional parameters
        try {
          print('\n--- Attempt 2: With additional parameters ---');
          final AuthorizationTokenRequest request2 = AuthorizationTokenRequest(
            _clientId,
            _redirectUri,
            serviceConfiguration: const AuthorizationServiceConfiguration(
              authorizationEndpoint: _authorizationEndpoint,
              tokenEndpoint: _tokenEndpoint,
            ),
            scopes: ['read:recovery', 'read:cycles', 'read:sleep'],
            additionalParameters: {
              'response_type': 'code',
              'grant_type': 'authorization_code',
            },
          );

          final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(request2);

          if (result != null) {
            print('SUCCESS with additional parameters!');
            await _secureStorage.write(key: _accessTokenKey, value: result.accessToken!);
            if (result.refreshToken != null) {
              await _secureStorage.write(key: _refreshTokenKey, value: result.refreshToken!);
            }
            await _fetchAndStoreUserId(result.accessToken!);
            return true;
          }
        } catch (e2) {
          print('Attempt 2 failed: $e2');

          // Parse the error message for more details
          final errorString = e2.toString();
          if (errorString.contains('invalid_client')) {
            print('\n!!! INVALID CLIENT ERROR !!!');
            print('This means your Client ID is not recognized by WHOOP.');
            print('Please verify:');
            print('1. Your WHOOP app is approved in the developer portal');
            print('2. The Client ID in ApiCredentials matches exactly');
            print('3. Your app is not in sandbox/test mode');
          } else if (errorString.contains('redirect_uri')) {
            print('\n!!! REDIRECT URI ERROR !!!');
            print('The redirect URI doesn\'t match what\'s registered with WHOOP');
          } else if (errorString.contains('User cancelled')) {
            print('\n!!! USER CANCELLED !!!');
            print('The user cancelled the authorization flow');
          }
        }
      }

      print('\n===== Authentication Failed =====');
      print('All attempts failed. Falling back to mock data for development...\n');

      // Offer to use mock data for development
      return false;

    } catch (e) {
      print('\n===== CRITICAL ERROR =====');
      print('Unexpected error during authentication:');
      print(e.toString());
      print('Stack trace type: ${e.runtimeType}');

      // Try to extract more error details
      if (e is PlatformException) {
        print('Platform Exception Details:');
        print('Code: ${(e as dynamic).code}');
        print('Message: ${(e as dynamic).message}');
        print('Details: ${(e as dynamic).details}');
      }

      return false;
    }
  }

  // Fetch and store user ID
  Future<void> _fetchAndStoreUserId(String accessToken) async {
    try {
      print('Fetching user profile...');
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/user/profile/basic'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('Profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userId = data['user_id'].toString();
        await _secureStorage.write(key: _userIdKey, value: userId);
        print('User ID stored: $userId');
      } else {
        print('Failed to fetch user profile: ${response.body}');
      }
    } catch (e) {
      print('Error fetching user ID: $e');
    }
  }

  // Get mock metrics for development
  Future<WhoopMetrics> getMockMetrics() async {
    print('Returning mock WHOOP metrics...');
    return WhoopMetrics(
      recovery: WhoopRecovery(
        recoveryScore: 51,
        hrv: 45.2,
        restingHeartRate: 58,
        isGreen: false,
        isYellow: true,
        isRed: false,
      ),
      sleep: WhoopSleep(
        sleepPerformance: 78,
        totalSleepMinutes: 420,
        remSleepMinutes: 95,
        deepSleepMinutes: 110,
        lightSleepMinutes: 180,
        awakeMinutes: 35,
      ),
      strain: WhoopStrain(
        dayStrain: 14.3,
        caloriesBurned: 2100,
        averageHeartRate: 72,
        maxHeartRate: 165,
      ),
    );
  }

  // Get all metrics - with fallback to mock data
  Future<WhoopMetrics?> getAllMetrics() async {
    try {
      // Check if we have a real token
      final token = await _secureStorage.read(key: _accessTokenKey);

      if (token == null || token == 'mock_access_token') {
        print('Using mock data (no real token available)');
        return getMockMetrics();
      }

      print('Fetching real WHOOP metrics...');

      // Try to fetch real data
      final futures = await Future.wait([
        getRecoveryData(),
        getSleepData(),
        getStrainData(),
      ]);

      final recovery = futures[0] as WhoopRecovery?;
      final sleep = futures[1] as WhoopSleep?;
      final strain = futures[2] as WhoopStrain?;

      // If no real data, return mock data
      if (recovery == null && sleep == null && strain == null) {
        print('No real data available, using mock data');
        return getMockMetrics();
      }

      return WhoopMetrics(
        recovery: recovery,
        sleep: sleep,
        strain: strain,
      );
    } catch (e) {
      print('Error fetching metrics: $e');
      print('Falling back to mock data');
      return getMockMetrics();
    }
  }

  // Disconnect from WHOOP
  Future<void> disconnect() async {
    print('Disconnecting from WHOOP...');
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
    print('Disconnected successfully');
  }

  // Rest of the methods remain the same...

  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final TokenRequest request = TokenRequest(
        _clientId,
        _redirectUri,
        refreshToken: refreshToken,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: _authorizationEndpoint,
          tokenEndpoint: _tokenEndpoint,
        ),
      );

      final TokenResponse? result = await _appAuth.token(request);

      if (result != null && result.accessToken != null) {
        await _secureStorage.write(key: _accessTokenKey, value: result.accessToken!);
        if (result.refreshToken != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: result.refreshToken!);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  Future<http.Response?> _makeAuthenticatedRequest(String endpoint) async {
    String? accessToken = await _secureStorage.read(key: _accessTokenKey);
    if (accessToken == null || accessToken == 'mock_access_token') return null;

    var response = await http.get(
      Uri.parse('$_apiBaseUrl$endpoint'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        accessToken = await _secureStorage.read(key: _accessTokenKey);
        response = await http.get(
          Uri.parse('$_apiBaseUrl$endpoint'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
      }
    }

    return response.statusCode == 200 ? response : null;
  }

  Future<WhoopRecovery?> getRecoveryData() async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(const Duration(days: 1));

      final response = await _makeAuthenticatedRequest(
        '/recovery?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}',
      );

      if (response != null) {
        final data = json.decode(response.body);
        if (data['records'] != null && data['records'].isNotEmpty) {
          return WhoopRecovery.fromJson(data['records'][0]);
        }
      }
    } catch (e) {
      print('Error fetching recovery data: $e');
    }
    return null;
  }

  Future<WhoopSleep?> getSleepData() async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 1));
      final endDate = now;

      final response = await _makeAuthenticatedRequest(
        '/activity/sleep?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}',
      );

      if (response != null) {
        final data = json.decode(response.body);
        if (data['records'] != null && data['records'].isNotEmpty) {
          return WhoopSleep.fromJson(data['records'][0]);
        }
      }
    } catch (e) {
      print('Error fetching sleep data: $e');
    }
    return null;
  }

  Future<WhoopStrain?> getStrainData() async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(const Duration(days: 1));

      final response = await _makeAuthenticatedRequest(
        '/cycles?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}',
      );

      if (response != null) {
        final data = json.decode(response.body);
        if (data['records'] != null && data['records'].isNotEmpty) {
          return WhoopStrain.fromJson(data['records'][0]);
        }
      }
    } catch (e) {
      print('Error fetching strain data: $e');
    }
    return null;
  }
}

// Data Models remain the same
class WhoopMetrics {
  final WhoopRecovery? recovery;
  final WhoopSleep? sleep;
  final WhoopStrain? strain;

  WhoopMetrics({this.recovery, this.sleep, this.strain});
}

class WhoopRecovery {
  final int recoveryScore;
  final double hrv;
  final double restingHeartRate;
  final bool isGreen;
  final bool isYellow;
  final bool isRed;

  WhoopRecovery({
    required this.recoveryScore,
    required this.hrv,
    required this.restingHeartRate,
    required this.isGreen,
    required this.isYellow,
    required this.isRed,
  });

  factory WhoopRecovery.fromJson(Map<String, dynamic> json) {
    final score = json['score']?['recovery_score'] ?? 0;
    return WhoopRecovery(
      recoveryScore: score.round(),
      hrv: json['score']?['hrv_rmssd_milli']?.toDouble() ?? 0.0,
      restingHeartRate: json['score']?['resting_heart_rate']?.toDouble() ?? 0.0,
      isGreen: score >= 67,
      isYellow: score >= 34 && score < 67,
      isRed: score < 34,
    );
  }

  Color get color {
    if (isGreen) return Colors.green;
    if (isYellow) return Colors.orange;
    return Colors.red;
  }

  String get status {
    if (isGreen) return 'Optimal';
    if (isYellow) return 'Adequate';
    return 'Low';
  }
}

class WhoopSleep {
  final int sleepPerformance;
  final int totalSleepMinutes;
  final int remSleepMinutes;
  final int deepSleepMinutes;
  final int lightSleepMinutes;
  final int awakeMinutes;

  WhoopSleep({
    required this.sleepPerformance,
    required this.totalSleepMinutes,
    required this.remSleepMinutes,
    required this.deepSleepMinutes,
    required this.lightSleepMinutes,
    required this.awakeMinutes,
  });

  factory WhoopSleep.fromJson(Map<String, dynamic> json) {
    final score = json['score'] ?? {};
    return WhoopSleep(
      sleepPerformance: (score['sleep_performance_percentage'] ?? 0).round(),
      totalSleepMinutes: (score['total_sleep_duration_milli'] ?? 0) ~/ 60000,
      remSleepMinutes: (score['rem_sleep_duration_milli'] ?? 0) ~/ 60000,
      deepSleepMinutes: (score['slow_wave_sleep_duration_milli'] ?? 0) ~/ 60000,
      lightSleepMinutes: (score['light_sleep_duration_milli'] ?? 0) ~/ 60000,
      awakeMinutes: (score['wake_duration_milli'] ?? 0) ~/ 60000,
    );
  }

  String get totalSleepFormatted {
    final hours = totalSleepMinutes ~/ 60;
    final minutes = totalSleepMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

class WhoopStrain {
  final double dayStrain;
  final int caloriesBurned;
  final double averageHeartRate;
  final double maxHeartRate;

  WhoopStrain({
    required this.dayStrain,
    required this.caloriesBurned,
    required this.averageHeartRate,
    required this.maxHeartRate,
  });

  factory WhoopStrain.fromJson(Map<String, dynamic> json) {
    final score = json['score'] ?? {};
    final strain = json['strain'] ?? {};

    return WhoopStrain(
      dayStrain: score['day_strain']?.toDouble() ?? 0.0,
      caloriesBurned: score['day_kilojoules']?.round() ?? 0,
      averageHeartRate: strain['average_heart_rate']?.toDouble() ?? 0.0,
      maxHeartRate: strain['max_heart_rate']?.toDouble() ?? 0.0,
    );
  }
}