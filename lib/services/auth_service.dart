import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class AuthService {
  final _apiService = ApiService();
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final user = await _apiService.login(email, password);
    
    if (user != null) {
      // Stocker la session utilisateur
      await saveToken(user['token']);
      await saveUserData(user['userData']);
    }

    return user;
  }

  Future<void> logout() async {
    await _apiService.logout();
    await clearStorage();
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<Map<String, String?>> getUserInfo() async {
    final userData = await getUserData();
    if (userData != null) {
      final Map<String, dynamic> userMap = jsonDecode(userData);
      return {
        'id': userMap['id'],
        'email': userMap['email'],
        'role': userMap['role'],
        'name': userMap['name'],
      };
    }
    return {};
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveUserData(String userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, userData);
  }

  Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userDataKey);
  }

  Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
  }
} 