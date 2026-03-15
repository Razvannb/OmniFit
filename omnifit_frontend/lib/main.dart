import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import the screens used in the app
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

// The main entry point of the Flutter application.
// This function is the first one to execute when the app starts.
void main() {
  // runApp tells Flutter to draw the OmniFitApp widget on the screen
  runApp(const OmniFitApp());
}

// Global configuration for app navigation using the go_router package.
// It acts like a map, connecting specific URLs/paths to specific screens.
final GoRouter _router = GoRouter(
  // The default screen the app opens when it starts
  initialLocation: '/',
  routes: [
    // Route for the Login Screen
    GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
    // Route for the Main Screen (Dashboard/Home area after login)
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainScreen(),
    ),
  ],
);

// The root widget of the entire application.
// It sets up the global design (theme) and the navigation structure.
class OmniFitApp extends StatelessWidget {
  const OmniFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We use MaterialApp.router instead of standard MaterialApp
    // to enable the go_router navigation system
    return MaterialApp.router(
      title: 'OmniFit', // The name of the app shown in the OS task manager
      // Global visual theme settings
      theme: ThemeData(
        // Automatically generates a matching color palette based on blue
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // Enables the modern Material Design 3 guidelines
        useMaterial3: true,
      ),

      // Hooks up the router configuration defined above to the app
      routerConfig: _router,
    );
  }
}
