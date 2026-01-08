import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _userData;
  final _dio = Dio();

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;

  Future<void> setToken(String token) async {
    _token = token;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> setUserData(Map<String, dynamic> userData) async {
    _userData = userData;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        _token = response.data['token'];
        _userData = response.data['data']['user'];
        _isAuthenticated = true;

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString(
          'user_data',
          response.data['data']['user'] != null
              ? jsonEncode(response.data['data']['user'])
              : '{}',
        );

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('auth_token')) {
      return;
    }

    final savedToken = prefs.getString('auth_token');
    final savedUserData = prefs.getString('user_data');

    if (savedToken == null || savedUserData == null) return;

    // Verify token is still valid for web platform
    if (kIsWeb) {
      try {
        final response = await _dio.get(
          'https://servicebackendnew-e2d8v.ondigitalocean.app/api/auth/profile',
          options: Options(
            headers: {'Authorization': 'Bearer $savedToken'},
            validateStatus: (status) => status! < 500,
          ),
        );
        
        if (response.statusCode != 200 || response.data['status'] != 'success') {
          await logout();
          return;
        }
      } catch (e) {
        await logout();
        return;
      }
    }

    _token = savedToken;
    _userData = jsonDecode(savedUserData) as Map<String, dynamic>?;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _userData = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    notifyListeners();
  }

  Future<void> refreshUserData() async {
    if (_token == null) return;

    try {
      // Debug print for token
      print('Using token: $_token');

      final response = await _dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/auth/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      // Debug prints for complete response data
      print('\n=== Complete API Response Debug Info ===');
      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Data: ${jsonEncode(response.data)}');
      print('Response Data Type: ${response.data.runtimeType}');
      if (response.data is Map) {
        print('\nResponse Data Structure:');
        response.data.forEach((key, value) {
          print('$key: ${value.runtimeType} = $value');
        });
      }
      print('=====================================\n');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        _userData = response.data['data']['user'];

        // Ensure company info fields exist
        if (_userData != null && !_userData!.containsKey('company')) {
          _userData!['company'] = null;
        }
        if (_userData != null &&
            !_userData!.containsKey('skippedCompanyInfo')) {
          _userData!['skippedCompanyInfo'] = false;
        }

        // Debug prints for refresh
        print('=== Refresh User Data Debug Info ===');
        print('Response Status: ${response.data['status']}');
        print('Updated User Data: $_userData');
        print('Company Info: ${_userData?['company']}');
        print('Skipped Company Info: ${_userData?['skippedCompanyInfo']}');
        print('================================');

        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_userData));

        notifyListeners();
      } else if (response.statusCode == 404) {
        print('User data endpoint not found. Please check the API endpoint.');
        // Consider implementing a retry mechanism or fallback
      }
    } catch (e) {
      print('Error refreshing user data: $e');
      if (e is DioException) {
        print('Error Response Status Code: ${e.response?.statusCode}');
        print('Error Response Data: ${e.response?.data}');
        print('Error Type: ${e.type}');
        print('Error Message: ${e.message}');
      }
      if (e is DioException && e.response?.statusCode == 401) {
        await logout();
      }
    }
  }
}
