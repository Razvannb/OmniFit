import 'package:flutter/material.dart';
import 'package:omnifit/screens/goals_screen.dart';
import 'package:omnifit/screens/nutrition_screen.dart';
import 'workout_screen.dart';
import '../ai_vision/pose_detector_view.dart';
import 'dashboard_screen.dart';

//  MAIN NAVIGATION SCREEN
// This is the root screen of the app after logging in.
// It holds the Bottom Navigation Bar and manages switching between different tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  //  STATE VARIABLES
  // Keeps track of the currently selected tab index (Defaults to 0: Dashboard)
  int _selectedIndex = 0;

  // Method triggered when a user taps a tab in the bottom navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the UI to show the selected screen
    });
  }

  @override
  Widget build(BuildContext context) {
    //  SCREENS LIST
    // A list of all the main screens corresponding to each tab in the navigation bar
    final List<Widget> screens = [
      // Index 0: Dashboard (Home)
      DashboardScreen(
        // Callback for the "Add Workout" quick action button on the dashboard
        onAddWorkout: () {
          // Directly open the LogWorkoutScreen to add a new workout
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const LogWorkoutScreen(), // Defined in workout_screen.dart
            ),
          ).then((_) {
            // After the workout is saved and the screen is closed,
            // switch the active bottom tab to "Workouts" (index 1)
            _onItemTapped(1);
          });
        },
        // Callback for the "View Goals" quick action button on the dashboard
        onViewGoals: () {
          // Navigate directly to the Goals tab (index 3)
          _onItemTapped(3);
        },
      ),
      // Index 1: Workouts List
      const WorkoutScreen(),
      // Index 2: Nutrition/Calories Log
      const NutritionScreen(userId: 1),
      // Index 3: Weekly Goals
      const GoalScreen(userId: 1),
      // Index 4: AI Form Check (Camera)
      const PoseDetectorView(),
    ];

    return Scaffold(
      // The body dynamically changes based on the currently selected tab index
      body: screens[_selectedIndex],

      //  BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType
            .fixed, // Keeps all items visible at all times
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex, // Highlights the currently active tab
        onTap: _onItemTapped, // Handles tab switching
        selectedItemColor: Colors.blueAccent, // Color for the active tab
        unselectedItemColor: Colors.grey, // Color for inactive tabs
        // Text styling for the active tab
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        // Text styling for the inactive tabs
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        elevation: 8, // Adds a subtle shadow above the navigation bar
        //  NAVIGATION ITEMS
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), // Inactive icon
            activeIcon: Icon(Icons.home), // Active (filled) icon
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label: 'Calories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Form Check',
          ),
        ],
      ),
    );
  }
}
