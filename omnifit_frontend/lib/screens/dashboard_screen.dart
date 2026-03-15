import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_screen.dart';
import 'hydration_screen.dart';
import 'meditation_screen.dart';

// Base URL for API requests (Localhost pointing to backend)
final String baseUrl = 'http://127.0.0.1:8080';

//  MAIN DASHBOARD SCREEN
// This is the home tab where users can see their daily overview, quick actions, and AI insights.
class DashboardScreen extends StatefulWidget {
  // Callbacks passed from the Main Navigation Screen to switch tabs
  final VoidCallback onAddWorkout;
  final VoidCallback onViewGoals;

  const DashboardScreen({
    super.key,
    required this.onAddWorkout,
    required this.onViewGoals,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  //  STATE VARIABLES
  // Default text shown while waiting for the API response
  String _aiRecommendation = "Loading your personalized recommendation...";

  // List to hold the dynamically fetched goals
  List<dynamic> _dashboardGoals = [];
  // Tracks the loading state for the goals chart
  bool _isLoadingGoals = true;

  @override
  void initState() {
    super.initState();
    // Fetch the AI recommendation from the backend as soon as the screen loads
    fetchRecommendation();
    // Fetch the weekly goals for the chart as soon as the screen loads
    fetchDashboardGoals();
  }

  //  API CALLS

  // Fetches a personalized AI recommendation based on the user's data
  Future<void> fetchRecommendation() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard?user_id=1'), // Fetching for user 1
      );

      // If the server responds successfully
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          // Update the UI with the fetched text
          setState(() {
            _aiRecommendation = data['recommendation'];
          });
        }
      }
    } catch (e) {
      // Handle network errors or server downtime
      print("Error AI recommendation: $e");
      if (mounted) {
        setState(() {
          _aiRecommendation = "We couldn't load the recommendation.";
        });
      }
    }
  }

  // Fetches the user's weekly set goals and current progress
  Future<void> fetchDashboardGoals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/goals?user_id=1'), // Fetching for user 1
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          // Update the UI with the fetched goals and stop the loader
          setState(() {
            _dashboardGoals = data;
            _isLoadingGoals = false;
          });
        }
      }
    } catch (e) {
      print("Error loading goals for dashboard: $e");
      if (mounted) {
        setState(() {
          _isLoadingGoals = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: const Text(
          'OmniFit',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Flat design
        foregroundColor: const Color.fromARGB(221, 0, 0, 0),
        actions: [
          // Profile Button in the top right corner
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onPressed: () {
              // Navigate to the Profile Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics:
            const BouncingScrollPhysics(), // Smooth bounce effect when scrolling
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Greeting
            _buildWelcomeHeader(),
            const SizedBox(height: 24),

            // 2. Weekly Progress Card (Muscle groups)
            _buildWeeklySetsGoal(),
            const SizedBox(height: 32),

            // 3. Quick Actions Title
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Quick Actions Grid (Add Workout, View Goals, etc.)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildQuickActionsGrid(context),
            ),
            const SizedBox(height: 32),

            // 5. AI Insight Card (Displays data fetched from API)
            _buildAIMessage(),
            const SizedBox(height: 32), // Bottom padding
          ],
        ),
      ),
    );
  }

  //  HELPER WIDGETS

  // Builds the top greeting text
  Widget _buildWelcomeHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, Champion! 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Here is your overview for today.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  // Builds the dark blue card displaying progress bars for different muscle groups
  Widget _buildWeeklySetsGoal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2447), // Dark navy blue background
        borderRadius: BorderRadius.circular(20),
      ),
      // Use a ternary operator to handle Loading -> Empty -> Populated states
      child: _isLoadingGoals
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _dashboardGoals.isEmpty
          ? const Center(
              child: Text(
                "No goals set yet.\nTap 'View Goals' to start tracking!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              // Map through the dynamic goals list and build a row for each
              children: _dashboardGoals.map((goal) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildMuscleProgressRow(
                    goal['muscleGroup'] ?? 'Unknown',
                    goal['currentSets'] ?? 0,
                    goal['targetSets'] ?? 0,
                  ),
                );
              }).toList(),
            ),
    );
  }

  // Builds a single row inside the Weekly Sets Goal card (Name, Progress Bar, Ratio)
  Widget _buildMuscleProgressRow(String title, int current, int target) {
    // Calculate progress fraction safely
    double progress = 0.0;
    if (target > 0) {
      progress = current / target;
    }

    // Handle edge cases like division by zero
    if (progress.isNaN || progress.isInfinite) progress = 0;
    if (progress > 1.0) progress = 1.0; // Cap at 100%

    return Row(
      children: [
        // Muscle Group Name
        SizedBox(
          width: 80,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        // Linear Progress Bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              // Turns green if the target is reached, otherwise stays blue
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.greenAccent : Colors.blueAccent,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Progress text (e.g., "10/14")
        SizedBox(
          width: 45,
          child: Text(
            '$current/$target',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Builds the 2x2 grid of action buttons
  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, // 2 items per row
      crossAxisSpacing: 24, // Horizontal space between cards
      mainAxisSpacing: 24, // Vertical space between cards
      childAspectRatio: 1.1, // Adjusts the shape to be slightly rectangular
      shrinkWrap:
          true, // Prevents layout issues inside the SingleChildScrollView
      physics:
          const NeverScrollableScrollPhysics(), // Disables internal scrolling
      children: [
        // Add Workout Card
        _buildSquareActionCard(
          Icons.add_box,
          'Add\nWorkout',
          Colors.blue,
          widget.onAddWorkout, // Uses callback from MainNavigation
        ),
        // View Goals Card
        _buildSquareActionCard(
          Icons.insert_chart_outlined,
          'View\nGoals',
          Colors.purple,
          widget.onViewGoals, // Uses callback from MainNavigation
        ),
        // Log Hydration Card
        _buildSquareActionCard(
          Icons.water_drop_outlined,
          'Log\nHydration',
          Colors.lightBlue,
          () {
            // Direct navigation
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HydrationScreen()),
            );
          },
        ),
        // Start Meditation Card
        _buildSquareActionCard(
          Icons.self_improvement_outlined,
          'Start\nMeditation',
          Colors.teal,
          () {
            // Direct navigation
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MeditationScreen()),
            );
          },
        ),
      ],
    );
  }

  // Builds individual cards for the Quick Actions grid
  Widget _buildSquareActionCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Soft shadow for depth
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon surrounded by a softly colored circle
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            // Multi-line label (e.g., "Add\nWorkout")
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the AI Insight card at the bottom
  Widget _buildAIMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.1),
        ), // Light blue border
      ),
      child: Row(
        children: [
          // Sparkle icon representing AI
          const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Insight',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                // Text dynamically loaded from the backend API
                Text(
                  _aiRecommendation,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
