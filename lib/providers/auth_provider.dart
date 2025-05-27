import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _apiService = ApiService();
  bool _isAuthenticated = false;
  Map<String, dynamic> _userInfo = {};
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic> get userInfo => _userInfo;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      
      if (userStr != null) {
        print('Found stored user data in AuthProvider');
        try {
          // Try to sync session with server
          await _apiService.syncSession();
          _userInfo = json.decode(userStr);
          _isAuthenticated = true;
        } catch (e) {
          print('Failed to sync session with server: $e');
          // Clear invalid session data
          await prefs.remove('user');
          _isAuthenticated = false;
          _userInfo = {};
        }
      } else {
        print('No stored user data found in AuthProvider');
        _isAuthenticated = false;
        _userInfo = {};
      }
    } catch (e) {
      print('Error checking auth status: $e');
      _isAuthenticated = false;
      _userInfo = {};
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      print('Attempting login for email: $email');  // Debug log
      final response = await _apiService.login(email, password);
      print('Login response: $response');  // Debug log
      
      if (response['success'] == true && response['user'] != null) {
        _userInfo = response['user'];
        _isAuthenticated = true;
        
        // Store user data in shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_userInfo));
        
        print('Login successful, user info: $_userInfo');  // Debug log
      } else {
        print('Login failed: Invalid credentials');  // Debug log
        _isAuthenticated = false;
        _userInfo = {};
      }
      
      _isLoading = false;
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      print('Login error: $e');  // Debug log
      _isAuthenticated = false;
      _userInfo = {};
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } finally {
      _isAuthenticated = false;
      _userInfo = {};
      notifyListeners();
      
      // Clear stored user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      await _apiService.updateUserProfile(profileData);
      _userInfo = {..._userInfo, ...profileData};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_userInfo));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      
      if (userData != null) {
        print('Found stored user data, checking session');
        final user = json.decode(userData);
        
        // Set the user state
        _userInfo = Map<String, dynamic>.from(user);
        _isAuthenticated = true;
        
        // Notify listeners
        notifyListeners();
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  Future<void> setUserData(Map<String, dynamic> userData) async {
    try {
      _userInfo = userData;
      _isAuthenticated = true;
      
      // Store user data in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(userData));
      
      notifyListeners();
      print('User data set directly in provider: $_userInfo');
    } catch (e) {
      print('Error setting user data: $e');
      rethrow;
    }
  }
} 