import 'package:flutter/material.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active workout')),
      body: const Center(
        child: Text('This is where we will track the sets and reps!'),
      ),
    );
  }
}