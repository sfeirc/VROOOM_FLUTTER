import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDrawer = Scaffold.of(context).hasDrawer;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Container(
      width: isDrawer ? null : 250,
      color: isDrawer ? null : Colors.blue.shade900,
      child: Column(
        children: [
          // Logo/Brand
          Container(
            padding: const EdgeInsets.all(16),
            color: isDrawer ? Colors.blue.shade900 : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isDesktop) Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
                if (!isDesktop) const SizedBox(width: 8),
                Text(
                  'VROOOM Admin',
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (isDrawer) const Divider(color: Colors.grey),
          if (!isDrawer) const Divider(color: Colors.white24),
          
          // Menu Items
          _buildMenuItem(
            context: context,
            index: 0,
            icon: Icons.dashboard,
            title: 'Aperçu',
          ),
          _buildMenuItem(
            context: context,
            index: 1,
            icon: Icons.directions_car,
            title: 'Véhicules',
          ),
          _buildMenuItem(
            context: context,
            index: 2,
            icon: Icons.people,
            title: 'Utilisateurs',
          ),
          _buildMenuItem(
            context: context,
            index: 3,
            icon: Icons.calendar_today,
            title: 'Réservations',
          ),
          if (isDrawer) const Spacer(),
          if (isDrawer) const Divider(color: Colors.grey),
          if (isDrawer) ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isSelected = selectedIndex == index;
    final isDrawer = Scaffold.of(context).hasDrawer;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected 
              ? (isDrawer ? Colors.blue.shade50 : Colors.white.withOpacity(0.1))
              : Colors.transparent,
            border: isSelected && !isDrawer
                ? Border(
                    left: const BorderSide(
                      color: Colors.white,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDrawer 
                  ? (isSelected ? Colors.blue.shade900 : Colors.grey.shade700)
                  : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: isDrawer 
                    ? (isSelected ? Colors.blue.shade900 : Colors.grey.shade700)
                    : Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 