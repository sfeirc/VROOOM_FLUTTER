import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
// Fournisseur d'authentification pour gérer l'état de connexion
class AuthProvider with ChangeNotifier {
  // Instance du service API
  final _apiService = ApiService();
  
  // Variables d'état
  bool _isAuthenticated = false;
  Map<String, dynamic> _userInfo = {};
  bool _isLoading = false;

  // Getters pour accéder aux variables d'état
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic> get userInfo => _userInfo;
  bool get isLoading => _isLoading;

  // Constructeur qui vérifie l'état d'authentification au démarrage
  AuthProvider() {
    _checkAuthStatus();
  }

  // Vérifie l'état d'authentification dans le stockage local
  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      
      if (userStr != null) {
        print('Données utilisateur trouvées dans le stockage');
        _userInfo = json.decode(userStr);
        _isAuthenticated = true;
      } else {
        print('Aucune donnée utilisateur trouvée dans le stockage');
        _isAuthenticated = false;
        _userInfo = {};
      }
    } catch (e) {
      print('Erreur lors de la vérification du statut d\'authentification: $e');
      _isAuthenticated = false;
      _userInfo = {};
    }
    
    // Met à jour l'état de chargement et notifie les écouteurs
    _isLoading = false;
    notifyListeners();
  }

  // Tente de connecter l'utilisateur avec email et mot de passe
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      print('Tentative de connexion pour l\'email: $email');
      final response = await _apiService.login(email, password);
      print('Réponse de connexion: $response');
      
      // Vérifie si la connexion a réussi
      _isAuthenticated = response['success'] ?? false;
      if (_isAuthenticated && response['user'] != null) {
        _userInfo = response['user'];
        print('Connexion réussie, informations utilisateur: $_userInfo');
      } else {
        print('Échec de la connexion: ${response['message'] ?? 'Erreur inconnue'}');
      }
      
      // Met à jour l'état et notifie les écouteurs
      _isLoading = false;
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      // Gère les erreurs de connexion
      print('Erreur de connexion: $e');
      _isAuthenticated = false;
      _userInfo = {};
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Déconnecte l'utilisateur et efface ses données
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } finally {
      // Réinitialise l'état
      _isAuthenticated = false;
      _userInfo = {};
      notifyListeners();
      
      // Efface les données de l'utilisateur du stockage local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    }
  }

  // Met à jour le profil de l'utilisateur
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      // Met à jour le profil via l'API
      await _apiService.updateUserProfile(profileData);
      
      // Met à jour les données locales
      _userInfo = {..._userInfo, ...profileData};
      
      // Sauvegarde dans le stockage local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_userInfo));
      
      // Notifie les écouteurs des changements
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Vérifie si l'utilisateur est déjà connecté
  Future<bool> checkLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      
      if (userData != null) {
        print('Données utilisateur trouvées, vérification de la session');
        final user = json.decode(userData);
        
        // Met à jour l'état avec les données utilisateur
        _userInfo = Map<String, dynamic>.from(user);
        _isAuthenticated = true;
        
        // Notifie les écouteurs des changements
        notifyListeners();
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erreur lors de la vérification du statut de connexion: $e');
      return false;
    }
  }

  // Définit directement les données de l'utilisateur
  Future<void> setUserData(Map<String, dynamic> userData) async {
    try {
      // Met à jour l'état
      _userInfo = userData;
      _isAuthenticated = true;
      
      // Stocke les données dans les préférences partagées
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(userData));
      
      // Notifie les écouteurs des changements
      notifyListeners();
      print('Données utilisateur définies dans le fournisseur: $_userInfo');
    } catch (e) {
      print('Erreur lors de la définition des données utilisateur: $e');
      rethrow;
    }
  }
} 