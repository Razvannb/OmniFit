import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/api_service.dart';

// Import the screens used in the app
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';

// The main entry point of the Flutter application.
void main() async {
  // Ensures Flutter framework binding is fully initialized before async logic
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load any previously saved session tokens dynamically
  await ApiService.init();
  
  // Launch the application
  runApp(const OmniFitApp());
}

// Global configuration for app navigation using the go_router package.
final GoRouter _router = GoRouter(
  // If the user has a valid active token, skip the login screen and go to dashboard directly!
  initialLocation: ApiService.isAuthenticated ? '/dashboard' : '/',
  routes: [
    // Route for the Login Screen
    GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
    
    // Route for the Register Screen
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    
    // Route for the Main Screen (Dashboard/Home area after login)
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainScreen(),
    ),
  ],
);

// The root widget of the entire application.
class OmniFitApp extends StatelessWidget {
  const OmniFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OmniFit',
      debugShowCheckedModeBanner: false, // Clean preview banner out
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D2447),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
