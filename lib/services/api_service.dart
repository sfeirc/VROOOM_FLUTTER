import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Changer pour l'URL absolue avec l'adresse du serveur
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Pattern Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Créer un client qui conserve les cookies
  final _client = http.Client();
  Map<String, String> _requestHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Stocker l'ID utilisateur pour l'authentification
  String? _userId;
  
  // Obtenir les données d'authentification stockées depuis SharedPreferences
  Future<void> _loadStoredAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger les données utilisateur si disponibles
    final storedUserId = prefs.getString('userId');
    if (storedUserId != null) {
      _userId = storedUserId;
      _updateAuthHeaders();
    }
  }

  // Méthode de déconnexion
  Future<void> logout() async {
    try {
      await _makeRequest('POST', '/auth/logout');
      
      // Effacer les cookies et les données de session
      await _clearSession();
      
      // Effacer l'ID utilisateur des en-têtes
      _userId = null;
      _updateAuthHeaders();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }
  
  // Synchroniser la session - pour les tentatives de reconnexion
  Future<void> syncSession() async {
    try {
      // Vérifier si nous avons l'ID utilisateur pour l'authentification
      if (_userId == null) {
        throw Exception('Non authentifié');
      }

      await _loadStoredAuthData();
    } catch (e) {
      print('Erreur de synchronisation de session: $e');
      rethrow;
    }
  }

  // Authentification
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      final userData = await _handleResponse(response);
      
      if (userData['success'] == true && userData['user'] != null) {
        _userId = userData['user']['id']?.toString();
        if (_userId != null) {
          _updateAuthHeaders();
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', _userId!);
        }
      }

      return userData;
    } catch (e) {
      print('Erreur de connexion: $e');
      rethrow;
    }
  }
  
  // Utilisateurs
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _makeRequest('GET', '/admin/users');
      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      rethrow;
    }
  }
  
  // Réservations
  Future<List<Map<String, dynamic>>> getReservations() async {
    try {
      final response = await _makeRequest('GET', '/admin/reservations');
      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erreur lors de la récupération des réservations: $e');
      rethrow;
    }
  }

  // Méthode auxiliaire pour gérer les réponses d'erreur
  Future<Map<String, dynamic>> _handleErrorResponse(http.Response response) async {
    try {
      final error = json.decode(response.body);
      return error;
    } catch (e) {
      return {'message': 'Erreur inconnue'};
    }
  }

  // Voitures
  Future<List<Map<String, dynamic>>> getCars({Map<String, String?>? filters}) async {
    try {
      // Construire l'URL avec les paramètres de requête pour les filtres
      var url = '/cars';
      if (filters != null && filters.isNotEmpty) {
        final queryParams = filters.entries
            .where((e) => e.value != null)
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value!)}')
            .join('&');
        url = '$url?$queryParams';
      }

      final response = await _makeRequest('GET', url);
      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erreur lors de la récupération des voitures: $e');
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

  // Utilisateurs
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

  // Méthode auxiliaire pour gérer les réponses API
  Future<dynamic> _handleResponse(http.Response response) async {
    print('Gestion de la réponse avec le code d\'état: ${response.statusCode}');  // Debug
    print('En-têtes de réponse: ${response.headers}');  // Debug des en-têtes

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decodedBody = json.decode(response.body);
        print('Décodage réussi du corps de la réponse: $decodedBody');  // Debug
        return decodedBody;
      } catch (e) {
        print('Erreur de décodage de la réponse réussie: $e');  // Debug
        throw Exception('Format de réponse invalide');
      }
    }
    
    if (response.statusCode == 401) {
      print('Échec d\'authentification - 401 Non autorisé');  // Debug
      await _clearSession();
      throw Exception('Non authentifié');
    }

    if (response.statusCode == 403) {
      print('Autorisation échouée - 403 Interdit');  // Debug
      throw Exception('Non autorisé');
    }

    if (response.statusCode == 404) {
      print('Ressource non trouvée - 404 Non trouvé');  // Debug
      throw Exception('Ressource non trouvée');
    }
    
    // Vérifier si la réponse est HTML (page d'erreur)
    if (response.headers['content-type']?.contains('text/html') ?? false) {
      throw Exception('Erreur serveur inattendue');
    }
    
    try {
      final error = json.decode(response.body);
      print('Corps de la réponse d\'erreur décodé: $error');  // Debug
      throw Exception(error['message'] ?? 'Erreur inconnue');
    } catch (e) {
      print('Erreur de décodage de la réponse d\'erreur: $e');  // Debug
      throw Exception('Erreur inconnue');
    }
  }

  // Marques
  Future<List<Map<String, dynamic>>> getBrands() async {
    print('Récupération des marques depuis: $baseUrl/cars/brands'); // Debug URL
    try {
      final response = await _makeRequest(
        'GET',
        '/cars/brands',
      );

      print('Statut de la réponse des marques: ${response.statusCode}'); // Debug statut
      print('Corps de la réponse des marques: ${response.body}'); // Debug corps

      final data = await _handleResponse(response);
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Format de données inattendu pour les marques: $data'); // Debug format
        throw Exception('Format de réponse invalide');
      }
    } catch (e) {
      print('Erreur lors de la récupération des marques: $e'); // Debug erreur
      rethrow;
    }
  }

  // Types
  Future<List<Map<String, dynamic>>> getTypes() async {
    print('Récupération des types depuis: $baseUrl/cars/types'); // Debug URL
    try {
      final response = await _makeRequest(
        'GET',
        '/cars/types',
      );

      print('Statut de la réponse des types: ${response.statusCode}'); // Debug statut
      print('Corps de la réponse des types: ${response.body}'); // Debug corps

      final data = await _handleResponse(response);
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Format de données inattendu pour les types: $data'); // Debug format
        throw Exception('Format de réponse invalide');
      }
    } catch (e) {
      print('Erreur lors de la récupération des types: $e'); // Debug erreur
      rethrow;
    }
  }

  // Opérations CRUD des voitures
  Future<Map<String, dynamic>> createCar(Map<String, dynamic> carData) async {
    try {
      // S'assurer que les champs numériques sont correctement formatés
      final formattedData = {
        ...carData,
        'Annee': carData['Annee']?.toString(),
        'PrixLocation': carData['PrixLocation']?.toString(),
        'NbPorte': carData['NbPorte']?.toString(),
        'NbPlaces': carData['NbPlaces']?.toString(),
        'Puissance': carData['Puissance']?.toString(),
      };

      final response = await _makeRequest(
        'POST',
        '/cars',
        body: formattedData,
      );
      return await _handleResponse(response);
    } catch (e) {
      print('Erreur lors de la création de la voiture: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCar(String carId, Map<String, dynamic> carData) async {
    try {
      // Convert numeric values to strings for the API
      final formattedData = {
        ...carData,
        'Annee': carData['Annee']?.toString(),
        'PrixLocation': carData['PrixLocation']?.toString(),
        'NbPorte': carData['NbPorte']?.toString(),
        'NbPlaces': carData['NbPlaces']?.toString(),
        'Puissance': carData['Puissance']?.toString(),
      };

      final response = await _makeRequest(
        'PUT',
        '/admin/cars/$carId',
        body: formattedData,
      );
      return await _handleResponse(response);
    } catch (e) {
      print('Erreur lors de la mise à jour de la voiture: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteCar(String carId) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '/cars/$carId',
      );
      await _handleResponse(response);
      // Retourner une map vide si succès
      return {};
    } catch (e) {
      print('Erreur lors de la suppression de la voiture: $e');
      rethrow;
    }
  }

  // Opérations CRUD des utilisateurs
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/users',
        body: userData,
      );
      return await _handleResponse(response);
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '/users/$userId',
        body: userData,
      );
      return await _handleResponse(response);
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'utilisateur: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '/users/$userId',
      );
      await _handleResponse(response);
      return {};
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur: $e');
      rethrow;
    }
  }

  // Opérations CRUD des réservations
  Future<Map<String, dynamic>> createReservationAdmin(Map<String, dynamic> reservationData) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/admin/reservations',
        body: reservationData,
      );
      return await _handleResponse(response);
    } catch (e) {
      print('Error creating reservation: $e');
      throw ApiException('Erreur lors de la création de la réservation: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateReservation(String reservationId, Map<String, dynamic> reservationData) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '/admin/reservations/$reservationId',
        body: reservationData,
      );
      return await _handleResponse(response);
    } catch (e) {
      print('Error updating reservation: $e');
      throw ApiException('Erreur lors de la mise à jour de la réservation: ${e.toString()}');
    }
  }

  Future<void> deleteReservation(String reservationId) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '/admin/reservations/$reservationId',
      );
      await _handleResponse(response);
    } catch (e) {
      print('Error deleting reservation: $e');
      throw ApiException('Erreur lors de la suppression de la réservation: ${e.toString()}');
    }
  }

  // Méthode pour mettre à jour les en-têtes d'authentification
  void _updateAuthHeaders() {
    if (_userId != null) {
      _requestHeaders['X-User-Id'] = _userId!;
    } else {
      _requestHeaders.remove('X-User-Id');
    }
  }

  // Méthode pour effacer la session
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _userId = null;
    _updateAuthHeaders();
  }

  // Méthode pour faire des requêtes HTTP
  Future<http.Response> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      ..._requestHeaders,
      if (body != null) 'Content-Type': 'application/json',
    };

    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'PUT':
        response = await _client.put(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Méthode HTTP non supportée: $method');
    }

    return response;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
} 