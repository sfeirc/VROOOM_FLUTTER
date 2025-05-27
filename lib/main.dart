import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

// Point d'entrée principal de l'application
// Configuration de l'application
// Initialisation des services
// Lancement de l'application

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Vroom Admin Dashboard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Remove hash and trailing slashes from routes
          if (settings.name == '/login' || settings.name == '/login/') {
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          } else if (settings.name == '/dashboard' || settings.name == '/dashboard/') {
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          } else if (settings.name == '/' || settings.name == '') {
            // For the root route, check authentication status
            return MaterialPageRoute(
              builder: (_) => Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  if (auth.isAuthenticated) {
                    return const DashboardScreen();
                  }
                  return const LoginScreen();
                },
              )
            );
          }
          // Default to login screen for unknown routes
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        },
      ),
    );
  }
}
