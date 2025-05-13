import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform, Process;
import 'dart:async';
import 'dart:isolate';

class ApiService {
  // URL de base de l'API (à modifier selon l'environnement)
  static String get baseUrl {
    if (kIsWeb) {
      // pour le web
      return 'http://localhost:3000/api';
    } else {
      // pour windows et autres plateformes, toujours utiliser la vm
      return 'http://localhost:3000/api';
    }
  }
  
  // Implémentation du pattern Singleton pour garantir une seule instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    print('API Service initialized with base URL: $baseUrl');
  }

  // Client HTTP qui conserve les cookies entre les requêtes
  final _client = http.Client();
  Map<String, String> _requestHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Identifiant de l'utilisateur pour l'authentification
  String? _userId;
  
  // Récupère les données d'authentification stockées
  Future<void> _initHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charge les données utilisateur si disponibles
    final userData = prefs.getString('user');
    if (userData != null) {
      print('Utilisation des données utilisateur stockées pour l\'authentification');
      final user = json.decode(userData);
      _userId = user['id'];
      if (_userId != null) {
        _requestHeaders['X-User-Id'] = _userId!;
        print('ID utilisateur ajouté aux en-têtes: $_userId');
      }
    }
  }

  // Méthode de déconnexion
  Future<void> logout() async {
    try {
      print('Déconnexion en cours');
      
      // Supprime les cookies et données de session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      
      // Supprime l'ID utilisateur des en-têtes
      _userId = null;
      _requestHeaders.remove('X-User-Id');
      
      print('Données utilisateur effacées du stockage et des en-têtes');
      return;
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      throw ApiException('Erreur lors de la déconnexion: ${e.toString()}');
    }
  }
  
  // Synchronise la session - pour les tentatives de reconnexion
  Future<bool> synchronizeSession() async {
    try {
      print('Synchronisation de la session');
      await _initHeaders();
      
      // Vérifie si nous avons un ID utilisateur pour l'authentification
      if (_userId != null) {
        print('Session synchronisée avec l\'ID utilisateur: $_userId');
        return true;
      }
      
      print('Aucun ID utilisateur disponible, échec de la synchronisation');
      return false;
    } catch (e) {
      print('Erreur de synchronisation de session: $e');
      return false;
    }
  }

  // Authentification de l'utilisateur
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await _initHeaders();
      
      print('Envoi de la requête de connexion à: $baseUrl/auth/login');
      print('En-têtes de la requête: $_requestHeaders');
      print('Corps de la requête: ${jsonEncode({
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

      print('Code de statut de la réponse: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');
      print('En-têtes de la réponse: ${response.headers}');
      
      final data = await _handleResponse(response);
      if (data['success'] == true && data['user'] != null) {
        // Stocke les données utilisateur localement
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        print('Données utilisateur stockées dans SharedPreferences');
        
        // Met à jour les en-têtes avec l'ID utilisateur
        _userId = data['user']['id'];
        if (_userId != null) {
          _requestHeaders['X-User-Id'] = _userId!;
          print('ID utilisateur mis à jour dans les en-têtes: $_userId');
        }
      }
      return data;
    } catch (e) {
      print('Détails de l\'erreur de connexion: $e');
      throw ApiException('Erreur de connexion: ${e.toString()}');
    }
  }
  
  // Gestion des utilisateurs
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
      print('Erreur lors de la récupération des utilisateurs: $e');
      throw ApiException('Erreur lors de la récupération des utilisateurs: ${e.toString()}');
    }
  }
  
  // Gestion des réservations
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
      print('Erreur lors de la récupération des réservations: $e');
      throw ApiException('Erreur lors de la récupération des réservations: ${e.toString()}');
    }
  }

  // Méthode utilitaire pour gérer les réponses d'erreur
  Exception _handleError(http.Response response) {
    print('Code de réponse d\'erreur: ${response.statusCode}');
    print('En-têtes de réponse d\'erreur: ${response.headers}');
    try {
      final Map<String, dynamic> errorData = json.decode(response.body);
      print('Corps de l\'erreur décodé: $errorData');
      return Exception(errorData['message'] ?? 'Erreur inconnue');
    } catch (e) {
      print('Erreur lors du décodage de la réponse d\'erreur: $e');
      return Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  // Gestion des voitures
  Future<List<Map<String, dynamic>>> getCars({
    Map<String, dynamic>? filters,
  }) async {
    try {
      await _initHeaders();
      
      // Construction de l'URL avec les paramètres de filtrage
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
      print('Erreur lors de la récupération des voitures: $e');
      rethrow;
    }
  }

  // Récupération des voitures en vedette
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

  // Gestion du profil utilisateur
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

  // Mise à jour du profil utilisateur
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

  // Création d'une réservation
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

  // Méthode utilitaire pour gérer les réponses API
  dynamic _handleResponse(http.Response response) async {
    print('Code de réponse: ${response.statusCode}');
    print('En-têtes de réponse: ${response.headers}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decodedBody = json.decode(response.body);
        print('Réponse décodée avec succès: $decodedBody');
        return decodedBody;
      } catch (e) {
        print('Erreur lors du décodage de la réponse: $e');
        throw ApiException('Erreur de format de réponse');
      }
    }
    
    if (response.statusCode == 401) {
      print('Authentification échouée - 401 Non autorisé');
      throw ApiException('Session expirée ou identifiants invalides');
    }

    if (response.statusCode == 403) {
      print('Autorisation échouée - 403 Interdit');
      throw ApiException('Accès non autorisé');
    }

    if (response.statusCode == 404) {
      print('Ressource non trouvée - 404');
      throw ApiException('Ressource non trouvée');
    }
    
    try {
      // Vérifie si la réponse est en HTML (page d'erreur)
      if (response.headers['content-type']?.contains('text/html') ?? false) {
        throw ApiException('Erreur serveur: ${response.statusCode}');
      }
      
      final error = json.decode(response.body);
      print('Corps de l\'erreur décodé: $error');
      throw ApiException(error['message'] ?? 'Une erreur est survenue');
    } catch (e) {
      print('Erreur lors du décodage de la réponse d\'erreur: $e');
      throw ApiException('Erreur serveur: ${response.statusCode}');
    }
  }

  // Gestion des marques de voitures
  Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      print('Récupération des marques depuis: $baseUrl/cars/brands');
      final response = await _client.get(
        Uri.parse('$baseUrl/cars/brands'),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      print('Code de réponse des marques: ${response.statusCode}');
      print('Corps de réponse des marques: ${response.body}');
      
      final data = await _handleResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      print('Format de données inattendu pour les marques: $data');
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des marques: $e');
      throw ApiException('Erreur lors de la récupération des marques: ${e.toString()}');
    }
  }

  // Gestion des types de véhicules
  Future<List<Map<String, dynamic>>> getTypes() async {
    try {
      print('Récupération des types depuis: $baseUrl/cars/types');
      final response = await _client.get(
        Uri.parse('$baseUrl/cars/types'),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      print('Code de réponse des types: ${response.statusCode}');
      print('Corps de réponse des types: ${response.body}');
      
      final data = await _handleResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      print('Format de données inattendu pour les types: $data');
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des types: $e');
      throw ApiException('Erreur lors de la récupération des types: ${e.toString()}');
    }
  }

  // Création d'une voiture
  Future<Map<String, dynamic>> createCar(Map<String, dynamic> carData) async {
    try {
      await _initHeaders();
      
      // Assure que les champs numériques sont correctement formatés
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
      
      // Assure que PhotosSupplementaires est une liste
      if (carData.containsKey('PhotosSupplementaires') && carData['PhotosSupplementaires'] is String) {
        // Si c'est une chaîne unique, la transformer en liste
        if (carData['PhotosSupplementaires'].toString().trim().isNotEmpty) {
          carData['PhotosSupplementaires'] = [carData['PhotosSupplementaires']];
        } else {
          carData['PhotosSupplementaires'] = [];
        }
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
      print('Erreur lors de la création de la voiture: $e');
      rethrow;
    }
  }

  // Mise à jour d'une voiture
  Future<void> updateCar(dynamic carId, Map<String, dynamic> carData) async {
    try {
      await _initHeaders();
      
      // Assure que les champs numériques sont correctement formatés
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
      
      // Assure que PhotosSupplementaires est une liste
      if (carData.containsKey('PhotosSupplementaires') && carData['PhotosSupplementaires'] is String) {
        // Si c'est une chaîne unique, la transformer en liste
        if (carData['PhotosSupplementaires'].toString().trim().isNotEmpty) {
          carData['PhotosSupplementaires'] = [carData['PhotosSupplementaires']];
        } else {
          carData['PhotosSupplementaires'] = [];
        }
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/cars/$carId'),
        headers: {..._requestHeaders, 'Content-Type': 'application/json'},
        body: json.encode(carData),
      );
      
      if (response.statusCode != 200) {
        throw _handleError(response);
      }
      
      return;
    } catch (e) {
      print('Erreur lors de la mise à jour de la voiture: $e');
      rethrow;
    }
  }

  // Suppression d'une voiture
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
      print('Erreur lors de la suppression de la voiture: $e');
      rethrow;
    }
  }

  // Opérations CRUD sur les utilisateurs
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
      print('Erreur lors de la création de l\'utilisateur: $e');
      throw ApiException('Erreur lors de la création de l\'utilisateur: ${e.toString()}');
    }
  }

  // Mise à jour d'un utilisateur
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
      print('Erreur lors de la mise à jour de l\'utilisateur: $e');
      throw ApiException('Erreur lors de la mise à jour de l\'utilisateur: ${e.toString()}');
    }
  }

  // Suppression d'un utilisateur
  Future<void> deleteUser(String userId) async {
    try {
      await _initHeaders();
      
      final response = await _client.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: _requestHeaders,
      );
      
      await _handleResponse(response);
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur: $e');
      throw ApiException('Erreur lors de la suppression de l\'utilisateur: ${e.toString()}');
    }
  }

  // Opérations CRUD sur les réservations
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
      print('Erreur lors de la création de la réservation: $e');
      throw ApiException('Erreur lors de la création de la réservation: ${e.toString()}');
    }
  }

  // Mise à jour d'une réservation
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
      print('Erreur lors de la mise à jour de la réservation: $e');
      throw ApiException('Erreur lors de la mise à jour de la réservation: ${e.toString()}');
    }
  }

  // Suppression d'une réservation
  Future<void> deleteReservation(String reservationId) async {
    try {
      await _initHeaders();
      
      final response = await _client.delete(
        Uri.parse('$baseUrl/admin/reservations/$reservationId'),
        headers: _requestHeaders,
      );
      
      await _handleResponse(response);
    } catch (e) {
      print('Erreur lors de la suppression de la réservation: $e');
      throw ApiException('Erreur lors de la suppression de la réservation: ${e.toString()}');
    }
  }
}

// Classe d'exception personnalisée pour les erreurs API
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
} 