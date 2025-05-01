import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final user = await _apiService.login(email, password);
    
    if (user != null) {
      // Store user session
      await _storage.write(key: 'user_id', value: user['id']);
      await _storage.write(key: 'user_role', value: user['role']);
      await _storage.write(key: 'user_email', value: user['email']);
      await _storage.write(key: 'user_name', value: user['name']);
    }

    return user;
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _storage.deleteAll();
  }

  Future<bool> isAuthenticated() async {
    final userId = await _storage.read(key: 'user_id');
    final userRole = await _storage.read(key: 'user_role');
    return userId != null && userRole == 'SUPERADMIN';
  }

  Future<Map<String, String?>> getUserInfo() async {
    return {
      'id': await _storage.read(key: 'user_id'),
      'email': await _storage.read(key: 'user_email'),
      'role': await _storage.read(key: 'user_role'),
      'name': await _storage.read(key: 'user_name'),
    };
  }
} 