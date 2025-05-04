// Importation des bibliothèques nécessaires
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard/dashboard_layout.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

// Écran principal du tableau de bord avec gestion d'état
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// État de l'écran du tableau de bord
class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Vérifie l'authentification au démarrage
    _checkUserAuth();
  }

  // Vérifie si l'utilisateur est authentifié
  Future<void> _checkUserAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Si déjà authentifié dans le provider, pas besoin de vérifier à nouveau
    if (authProvider.isAuthenticated) {
      print('Utilisateur déjà authentifié dans le provider, vérification ignorée');
      return;
    }
    
    try {
      // Vérifie si nous avons des données utilisateur valides
      final isLoggedIn = await authProvider.checkLoggedIn();
      
      if (!isLoggedIn && mounted) {
        // Si non connecté, redirige vers la page de connexion
        print('Non connecté, redirection vers l\'écran de connexion');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Erreur de vérification d\'authentification: $e');
      // Gère les erreurs en redirigeant vers l'écran de connexion
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isAuthenticated) {
            // Redirige vers la connexion si non authentifié
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/login');
            });
            // Affiche un indicateur de chargement pendant la redirection
            return const Center(child: CircularProgressIndicator());
          }

          // Affiche la mise en page du tableau de bord si authentifié
          return const DashboardLayout();
        },
      ),
    );
  }
} 