import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_credentials.dart';

class WhoopService {
  static const String _clientId = ApiCredentials.whoopClientId;
  static const String _clientSecret = ApiCredentials.whoopClientSecret;
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

  // Authenticate with WHOOP
  Future<bool> authenticate() async {
    try {
      // Configure the authorization request
      final AuthorizationTokenRequest request = AuthorizationTokenRequest(
        _clientId,
        _redirectUri,
        clientSecret: _clientSecret,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: _authorizationEndpoint,
          tokenEndpoint: _tokenEndpoint,
        ),
        scopes: [
          'read:recovery',
          'read:cycles',
          'read:sleep',
          'read:workout',
          'read:profile',
          'read:body_measurement'
        ],
        promptValues: ['login'],
      );

      // Perform the authorization request
      final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(request);

      if (result != null) {
        // Store tokens securely
        await _secureStorage.write(key: _accessTokenKey, value: result.accessToken!);
        if (result.refreshToken != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: result.refreshToken!);
        }

        // Get and store user ID
        await _fetchAndStoreUserId(result.accessToken!);

        return true;
      }
      return false;
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  // Fetch and store user ID
  Future<void> _fetchAndStoreUserId(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/user/profile/basic'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userId = data['user_id'].toString();
        await _secureStorage.write(key: _userIdKey, value: userId);
      }
    } catch (e) {
      print('Error fetching user ID: $e');
    }
  }

  // Refresh access token
  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final TokenRequest request = TokenRequest(
        _clientId,
        _redirectUri,
        clientSecret: _clientSecret,
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

  // Make authenticated API request
  Future<http.Response?> _makeAuthenticatedRequest(String endpoint) async {
    String? accessToken = await _secureStorage.read(key: _accessTokenKey);

    if (accessToken == null) return null;

    var response = await http.get(
      Uri.parse('$_apiBaseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    // If unauthorized, try refreshing token
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        accessToken = await _secureStorage.read(key: _accessTokenKey);
        response = await http.get(
          Uri.parse('$_apiBaseUrl$endpoint'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );
      }
    }

    return response.statusCode == 200 ? response : null;
  }

  // Get recovery data
  Future<WhoopRecovery?> getRecoveryData() async {
    try {
      final userId = await _secureStorage.read(key: _userIdKey);
      if (userId == null) return null;

      // Get today's recovery
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

  // Get sleep data
  Future<WhoopSleep?> getSleepData() async {
    try {
      final userId = await _secureStorage.read(key: _userIdKey);
      if (userId == null) return null;

      // Get last night's sleep
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

  // Get strain data
  Future<WhoopStrain?> getStrainData() async {
    try {
      final userId = await _secureStorage.read(key: _userIdKey);
      if (userId == null) return null;

      // Get today's strain
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

  // Get all metrics
  Future<WhoopMetrics?> getAllMetrics() async {
    try {
      final recovery = await getRecoveryData();
      final sleep = await getSleepData();
      final strain = await getStrainData();

      return WhoopMetrics(
        recovery: recovery,
        sleep: sleep,
        strain: strain,
      );
    } catch (e) {
      print('Error fetching all metrics: $e');
      return null;
    }
  }

  // Disconnect from WHOOP
  Future<void> disconnect() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
  }
}

// Data Models
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