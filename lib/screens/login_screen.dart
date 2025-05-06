import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

// Écran de connexion avec gestion d'état
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// État de l'écran de connexion
class _LoginScreenState extends State<LoginScreen> {
  // Clé du formulaire pour la validation
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs de saisie
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Variables d'état
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  
  // Instance du service API
  final _apiService = ApiService();

  @override
  void dispose() {
    // Libération des ressources
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Méthode de connexion
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final success = await context.read<AuthProvider>().login(
          _emailController.text,
          _passwordController.text,
        );

        if (success && mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de connexion: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
        // Décoration avec dégradé de couleurs
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade800,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and Title
                  Icon(
                    Icons.directions_car,
                    size: isSmallScreen ? 64 : 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VROOOM Admin',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tableau de bord d\'administration',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 16 : 18,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),

                  // Login Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: isSmallScreen ? double.infinity : 400,
                      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Connexion',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre email';
                                }
                                if (!value.contains('@')) {
                                  return 'Veuillez entrer un email valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe';
                                }
                                if (value.length < 6) {
                                  return 'Le mot de passe doit contenir au moins 6 caractères';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Login Button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade900,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('Se connecter'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 