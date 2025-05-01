import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change back to absolute URL with server address
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Create a client that persists cookies
  final _client = http.Client();
  Map<String, String> _requestHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Store user ID for authentication
  String? _userId;
  
  // Get stored auth data from SharedPreferences
  Future<void> _initHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load user data if available
    final userData = prefs.getString('user');
    if (userData != null) {
      print('Using stored user data for authentication');
      final user = json.decode(userData);
      _userId = user['id'];
      if (_userId != null) {
        _requestHeaders['X-User-Id'] = _userId!;
        print('Added User ID to headers: $_userId');
      }
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      print('Logging out');
      
      // Clear cookies and session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      
      // Clear user ID from headers
      _userId = null;
      _requestHeaders.remove('X-User-Id');
      
      print('User data cleared from storage and headers');
      return;
    } catch (e) {
      print('Logout error: $e');
      throw ApiException('Erreur lors de la déconnexion: ${e.toString()}');
    }
  }
  
  // Sync session - for reconnection attempts
  Future<bool> synchronizeSession() async {
    try {
      print('Synchronizing session');
      await _initHeaders();
      
      // Check if we have user ID for authentication
      if (_userId != null) {
        print('Session synchronized with User ID: $_userId');
        return true;
      }
      
      print('No user ID available, session sync failed');
      return false;
    } catch (e) {
      print('Session synchronization error: $e');
      return false;
    }
  }

  // Authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await _initHeaders();
      
      print('Making login request to: $baseUrl/auth/login');
      print('Request headers: $_requestHeaders');
      print('Request body: ${jsonEncode({
        'email': email,
        'password': password,
      })}');

      final response = await _client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _requestHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');
      
      final data = await _handleResponse(response);
      if (data['success'] == true && data['user'] != null) {
        // Store user data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        print('User data stored in SharedPreferences');
        
        // Update headers with user ID
        _userId = data['user']['id'];
        if (_userId != null) {
          _requestHeaders['X-User-Id'] = _userId!;
          print('Updated User ID in headers: $_userId');
        }
      }
      return data;
    } catch (e) {
      print('Login error details: $e');
      throw ApiException('Erreur de connexion: ${e.toString()}');
    }
  }
  
  // Users
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      await _initHeaders();
      
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: _requestHeaders,
      );
      
      final data = await _handleResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error in getUsers: $e');
      throw ApiException('Erreur lors de la récupération des utilisateurs: ${e.toString()}');
    }
  }
  
  // Reservations
  Future<List<Map<String, dynamic>>> getReservations() async {
    try {
      await _initHeaders();
      
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/reservations'),
        headers: _requestHeaders,
      );
      
      final data = await _handleResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error in getReservations: $e');
      throw ApiException('Erreur lors de la récupération des réservations: ${e.toString()}');
    }
  }

  // Helper method to handle error responses
  Exception _handleError(http.Response response) {
    print('Error response status: ${response.statusCode}');
    print('Error response headers: ${response.headers}');
    try {
      final Map<String, dynamic> errorData = json.decode(response.body);
      print('Error response body decoded: $errorData');
      return Exception(errorData['message'] ?? 'Unknown error');
    } catch (e) {
      print('Error decoding error response: $e');
      return Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  // Cars
  Future<List<Map<String, dynamic>>> getCars({
    Map<String, dynamic>? filters,
  }) async {
    try {
      await _initHeaders();
      
      // Build URL with query parameters for filters
      final Uri uri = Uri.parse('$baseUrl/cars');
      Uri filteredUri = uri;
      
      if (filters != null && filters.isNotEmpty) {
        final queryParams = <String, String>{};
        if (filters.containsKey('brand')) {
          queryParams['brand'] = filters['brand'].toString();
        }
        if (filters.containsKey('type')) {
          queryParams['type'] = filters['type'].toString();
        }
        if (filters.containsKey('search')) {
          queryParams['search'] = filters['search'].toString();
        }
        
        filteredUri = uri.replace(queryParameters: queryParams);
      }
      
      final response = await http.get(
        filteredUri,
        headers: _requestHeaders,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print('Error getting cars: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFeaturedCars() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/cars/featured'),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      final data = await _handleResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      throw ApiException('Erreur lors de la récupération des véhicules en vedette: ${e.toString()}');
    }
  }

  // Users
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      return await _handleResponse(response);
    } catch (e) {
      throw ApiException('Erreur lors de la récupération du profil: ${e.toString()}');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(profileData),
      );
      
      await _handleResponse(response);
    } catch (e) {
      throw ApiException('Erreur lors de la mise à jour du profil: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createReservation({
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    required double amount,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/reservations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'carId': carId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'amount': amount,
        }),
      );
      
      return await _handleResponse(response);
    } catch (e) {
      throw ApiException('Erreur lors de la création de la réservation: ${e.toString()}');
    }
  }

  // Helper method to handle API responses
  dynamic _handleResponse(http.Response response) async {
    print('Handling response with status code: ${response.statusCode}');  // Debug
    print('Response headers: ${response.headers}');  // Debug headers

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decodedBody = json.decode(response.body);
        print('Successfully decoded response body: $decodedBody');  // Debug
        return decodedBody;
      } catch (e) {
        print('Error decoding successful response: $e');  // Debug
        throw ApiException('Erreur de format de réponse');
      }
    }
    
    if (response.statusCode == 401) {
      print('Authentication failed - 401 Unauthorized');  // Debug
      throw ApiException('Session expirée ou identifiants invalides');
    }

    if (response.statusCode == 403) {
      print('Authorization failed - 403 Forbidden');  // Debug
      throw ApiException('Accès non autorisé');
    }

    if (response.statusCode == 404) {
      print('Resource not found - 404 Not Found');  // Debug
      throw ApiException('Ressource non trouvée');
    }
    
    try {
      // Check if response is HTML (error page)
      if (response.headers['content-type']?.contains('text/html') ?? false) {
        throw ApiException('Erreur serveur: ${response.statusCode}');
      }
      
      final error = json.decode(response.body);
      print('Error response body decoded: $error');  // Debug
      throw ApiException(error['message'] ?? 'Une erreur est survenue');
    } catch (e) {
      print('Error decoding error response: $e');  // Debug
      throw ApiException('Erreur serveur: ${response.statusCode}');
    }
  }

  // Brands
  Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      print('Fetching brands from: $baseUrl/cars/brands'); // Debug URL
      final response = await _client.get(
        Uri.parse('$baseUrl/cars/brands'),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      print('Brands response status: ${response.statusCode}'); // Debug status
      print('Brands response body: ${response.body}'); // Debug body
      
      final data = await _handleResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      print('Unexpected data format for brands: $data'); // Debug format
      return [];
    } catch (e) {
      print('Error fetching brands: $e'); // Debug error
      throw ApiException('Erreur lors de la récupération des marques: ${e.toString()}');
    }
  }

  // Types
  Future<List<Map<String, dynamic>>> getTypes() async {
    try {
      print('Fetching types from: $baseUrl/cars/types'); // Debug URL
      final response = await _client.get(
        Uri.parse('$baseUrl/cars/types'),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      print('Types response status: ${response.statusCode}'); // Debug status
      print('Types response body: ${response.body}'); // Debug body
      
      final data = await _handleResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      print('Unexpected data format for types: $data'); // Debug format
      return [];
    } catch (e) {
      print('Error fetching types: $e'); // Debug error
      throw ApiException('Erreur lors de la récupération des types: ${e.toString()}');
    }
  }

  // Cars CRUD Operations
  Future<Map<String, dynamic>> createCar(Map<String, dynamic> carData) async {
    try {
      await _initHeaders();
      
      // Make sure numeric fields are properly formatted 
      if (carData.containsKey('Annee') && carData['Annee'] is String) {
        carData['Annee'] = int.parse(carData['Annee'].toString());
      }
      
      if (carData.containsKey('PrixLocation') && carData['PrixLocation'] is String) {
        carData['PrixLocation'] = double.parse(carData['PrixLocation'].toString());
      }
      
      if (carData.containsKey('NbPorte') && carData['NbPorte'] is String) {
        carData['NbPorte'] = int.parse(carData['NbPorte'].toString());
      }
      
      if (carData.containsKey('NbPlaces') && carData['NbPlaces'] is String) {
        carData['NbPlaces'] = int.parse(carData['NbPlaces'].toString());
      }
      
      if (carData.containsKey('Puissance') && carData['Puissance'] is String) {
        carData['Puissance'] = int.parse(carData['Puissance'].toString());
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/cars'),
        headers: {..._requestHeaders, 'Content-Type': 'application/json'},
        body: json.encode(carData),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print('Error creating car: $e');
      rethrow;
    }
  }

  Future<void> updateCar(dynamic carId, Map<String, dynamic> carData) async {
    try {
      await _initHeaders();
      
      // Make sure numeric fields are properly formatted 
      if (carData.containsKey('Annee') && carData['Annee'] is String) {
        carData['Annee'] = int.parse(carData['Annee'].toString());
      }
      
      if (carData.containsKey('PrixLocation') && carData['PrixLocation'] is String) {
        carData['PrixLocation'] = double.parse(carData['PrixLocation'].toString());
      }
      
      if (carData.containsKey('NbPorte') && carData['NbPorte'] is String) {
        carData['NbPorte'] = int.parse(carData['NbPorte'].toString());
      }
      
      if (carData.containsKey('NbPlaces') && carData['NbPlaces'] is String) {
        carData['NbPlaces'] = int.parse(carData['NbPlaces'].toString());
      }
      
      if (carData.containsKey('Puissance') && carData['Puissance'] is String) {
        carData['Puissance'] = int.parse(carData['Puissance'].toString());
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/cars/$carId'),
        headers: {..._requestHeaders, 'Content-Type': 'application/json'},
        body: json.encode(carData),
      );
      
      if (response.statusCode != 200) {
        throw _handleError(response);
      }
      
      // Return empty map if successful
      return;
    } catch (e) {
      print('Error updating car: $e');
      rethrow;
    }
  }

  Future<void> deleteCar(dynamic carId) async {
    try {
      await _initHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/cars/$carId'),
        headers: _requestHeaders,
      );
      
      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } catch (e) {
      print('Error deleting car: $e');
      rethrow;
    }
  }

  // Users CRUD Operations
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      await _initHeaders();
      
      final response = await _client.post(
        Uri.parse('$baseUrl/admin/users'),
        headers: _requestHeaders,
        body: jsonEncode(userData),
      );
      
      return await _handleResponse(response);
    } catch (e) {
      print('Error creating user: $e');
      throw ApiException('Erreur lors de la création de l\'utilisateur: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _initHeaders();
      
      final response = await _client.put(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: _requestHeaders,
        body: jsonEncode(userData),
      );
      
      return await _handleResponse(response);
    } catch (e) {
      print('Error updating user: $e');
      throw ApiException('Erreur lors de la mise à jour de l\'utilisateur: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _initHeaders();
      
      final response = await _client.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: _requestHeaders,
      );
      
      await _handleResponse(response);
    } catch (e) {
      print('Error deleting user: $e');
      throw ApiException('Erreur lors de la suppression de l\'utilisateur: ${e.toString()}');
    }
  }

  // Reservations CRUD Operations
  Future<Map<String, dynamic>> createReservationAdmin(Map<String, dynamic> reservationData) async {
    try {
      await _initHeaders();
      
      final response = await _client.post(
        Uri.parse('$baseUrl/admin/reservations'),
        headers: _requestHeaders,
        body: jsonEncode(reservationData),
      );
      
      return await _handleResponse(response);
    } catch (e) {
      print('Error creating reservation: $e');
      throw ApiException('Erreur lors de la création de la réservation: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateReservation(String reservationId, Map<String, dynamic> reservationData) async {
    try {
      await _initHeaders();
      
      final response = await _client.put(
        Uri.parse('$baseUrl/admin/reservations/$reservationId'),
        headers: _requestHeaders,
        body: jsonEncode(reservationData),
      );
      
      return await _handleResponse(response);
    } catch (e) {
      print('Error updating reservation: $e');
      throw ApiException('Erreur lors de la mise à jour de la réservation: ${e.toString()}');
    }
  }

  Future<void> deleteReservation(String reservationId) async {
    try {
      await _initHeaders();
      
      final response = await _client.delete(
        Uri.parse('$baseUrl/admin/reservations/$reservationId'),
        headers: _requestHeaders,
      );
      
      await _handleResponse(response);
    } catch (e) {
      print('Error deleting reservation: $e');
      throw ApiException('Erreur lors de la suppression de la réservation: ${e.toString()}');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
} 