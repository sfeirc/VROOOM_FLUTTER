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
  bool _isDrawerOpen = false;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    if (isDesktop) {
      return _buildDesktopLayout(userName);
    } else {
      return _buildMobileTabletLayout(userName, isTablet);
    }
  }

  Widget _buildDesktopLayout(String userName) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
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
                _buildTopBar(userName),
                _buildMainContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabletLayout(String userName, bool isTablet) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _buildUserProfile(userName, isTablet),
        ],
      ),
      drawer: Drawer(
        child: SidebarMenu(
          selectedIndex: _selectedIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedIndex = index;
              Navigator.pop(context);
            });
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 1200, // Maximum width for content
            ),
            child: _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String userName) {
    return Container(
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
          _buildUserProfile(userName, true),
        ],
      ),
    );
  }

  Widget _buildUserProfile(String userName, bool isLarge) {
    return PopupMenuButton(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade900,
            radius: isLarge ? 20 : 16,
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
              style: TextStyle(
                color: Colors.white,
                fontSize: isLarge ? 16 : 14,
              ),
                              ),
                            ),
          if (isLarge) ...[
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
    );
  }

  Widget _buildMainContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth > 768 ? 24.0 : 16.0;
    
    return Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding,
        ),
                    child: _screens[_selectedIndex],
      ),
    );
  }
} 