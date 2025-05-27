import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/sidebar_menu.dart';
import 'screens/cars_screen.dart';
import 'screens/users_screen.dart';
import 'screens/reservations_screen.dart';
import 'screens/overview_screen.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const OverviewScreen(),
    const CarsScreen(),
    const UsersScreen(),
    const ReservationsScreen(),
  ];

  final List<String> _titles = [
    'Aperçu',
    'Gestion des Véhicules',
    'Gestion des Utilisateurs',
    'Gestion des Réservations',
  ];

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().userInfo['name'] ?? 'Admin';

    return Scaffold(
      body: Row(
        children: [
          // Mise en page du tableau de bord
          // Barre latérale
          SidebarMenu(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _titles[_selectedIndex],
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // User Profile
                      PopupMenuButton(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade900,
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.logout),
                              title: const Text('Déconnexion'),
                              onTap: () {
                                context.read<AuthProvider>().logout();
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Main Content Area
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    padding: const EdgeInsets.all(24),
                    child: _screens[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 