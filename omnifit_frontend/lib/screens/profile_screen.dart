import 'package:flutter/material.dart';

//  PROFILE SCREEN
// This screen displays the user's profile information and account-related settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Light grey background for a clean, modern look
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Flat design with no shadow
        foregroundColor: Colors.black87, // Text and icon color
        centerTitle: true, // Centers the title in the AppBar
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 48), // Top spacing
            //  PROFILE HEADER SECTION
            _buildProfileHeader(),

            const SizedBox(height: 48), // Spacing before menu options
            //  MENU OPTIONS
            // Log Out Button (marked as destructive so it appears red)
            _buildMenuOption(
              icon: Icons.logout,
              title: 'Log Out',
              isDestructive: true,
              onTap: () {
                // Add your logout logic here in the future
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Builds the user avatar, name, and email
  Widget _buildProfileHeader() {
    return const Column(
      children: [
        // User profile picture placeholder
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        SizedBox(height: 16),
        // User's display name
        Text(
          'Alex Fitness',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        // User's email address
        Text(
          'alex.fitness@example.com',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  // Helper Widget: Builds a stylish menu row (ListTile) inside a card
  // [isDestructive] determines if the button should be styled with red (e.g., for Log Out or Delete Account)
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    // Determine text color based on whether the action is destructive
    final color = isDestructive ? Colors.red : Colors.black87;

    // Determine the background color of the circular icon wrapper
    final iconBgColor = isDestructive
        ? Colors.red.withOpacity(0.1)
        : Colors.blueAccent.withOpacity(0.1);

    // Determine the color of the icon itself
    final iconColor = isDestructive ? Colors.red : Colors.blueAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Subtle shadow for depth
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        // Leading icon wrapped in a circular, lightly colored container
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        // Option title text
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: color,
          ),
        ),
        // Action triggered when the row is tapped
        onTap: onTap,
      ),
    );
  }
}
