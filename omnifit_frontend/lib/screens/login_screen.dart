import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background color of the screen
      backgroundColor: const Color(0xFFF8F9FB), 
      
      appBar: AppBar(
        // Apply TextStyle to make the text bold
        title: const Text(
          'Login OmniFit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0, // Remove the shadow under the title for a more modern look
      ),
      
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/dashboard');
          },
          child: const Text('Login'),
        ),
      ),
    );
  }
}
