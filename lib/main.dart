// Importation des bibliothèques nécessaires
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

// Point d'entrée de l'application
void main() {
  runApp(const MyApp());
}

// Widget principal de l'application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Configuration des fournisseurs d'état
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'VROOOM Prestige - Administration',
        debugShowCheckedModeBanner: false,
        // Configuration du thème de l'application
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/',
        // Gestionnaire de routes de l'application
        onGenerateRoute: (settings) {
          // Supprime le hash et les slashes de fin des routes
          if (settings.name == '/login' || settings.name == '/login/') {
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          } else if (settings.name == '/dashboard' || settings.name == '/dashboard/') {
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          } else if (settings.name == '/' || settings.name == '') {
            // Pour la route racine, vérifie l'état d'authentification
            return MaterialPageRoute(
              builder: (_) => Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  // Redirige vers le tableau de bord si authentifié, sinon vers la connexion
                  if (auth.isAuthenticated) {
                    return const DashboardScreen();
                  }
                  return const LoginScreen();
                },
              )
            );
          }
          // Par défaut, redirige vers l'écran de connexion pour les routes inconnues
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        },
      ),
    );
  }
}
