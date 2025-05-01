import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard/dashboard_layout.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAuth();
  }

  Future<void> _checkUserAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // If already authenticated in provider, no need to check again
    if (authProvider.isAuthenticated) {
      print('User already authenticated in provider, skipping check');
      return;
    }
    
    try {
      // Check if we have valid user data
      final isLoggedIn = await authProvider.checkLoggedIn();
      
      if (!isLoggedIn && mounted) {
        // If not logged in, redirect to login using named route
        print('Not logged in, redirecting to login screen');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Auth check error: $e');
      // Handle errors by directing to login screen using named route
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
            // Redirect to login if not authenticated
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/login');
            });
            return const Center(child: CircularProgressIndicator());
          }

          // Show the dashboard layout if authenticated
          return const DashboardLayout();
        },
      ),
    );
  }
} 