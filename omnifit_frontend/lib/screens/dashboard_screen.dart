import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_screen.dart';
import 'hydration_screen.dart';
import 'meditation_screen.dart';

final String baseUrl = 'http://127.0.0.1:8080';

class DashboardScreen extends StatefulWidget {
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
  String _aiRecommendation = "Loading your personalized recommendation...";

  @override
  void initState() {
    super.initState();
    fetchRecommendation();
  }

  Future<void> fetchRecommendation() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard?user_id=1'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _aiRecommendation = data['recommendation'];
        });
      }
    } catch (e) {
      print("Error AI recommendation: $e");
      setState(() {
        _aiRecommendation = "We couldn't load the recommendation.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'OmniFit',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color.fromARGB(221, 0, 0, 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildWeeklySetsGoal(),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildQuickActionsGrid(context),
            ),
            const SizedBox(height: 32),
            _buildAIMessage(), // Aici va apărea mesajul nostru
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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

  Widget _buildWeeklySetsGoal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2447),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildMuscleProgressRow('Chest', 10, 14),
          const SizedBox(height: 16),
          _buildMuscleProgressRow('Back', 18, 20),
          const SizedBox(height: 16),
          _buildMuscleProgressRow('Legs', 8, 12),
          const SizedBox(height: 16),
          _buildMuscleProgressRow('Shoulders', 6, 10),
          const SizedBox(height: 16),
          _buildMuscleProgressRow('Arms', 12, 12),
        ],
      ),
    );
  }

  Widget _buildMuscleProgressRow(String title, int current, int target) {
    double progress = current / target;
    if (progress.isNaN || progress.isInfinite) progress = 0;
    if (progress > 1.0) progress = 1.0;

    return Row(
      children: [
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
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.blueAccent,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 16),
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

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSquareActionCard(
          Icons.add_box,
          'Add\nWorkout',
          Colors.blue,
          widget.onAddWorkout,
        ),
        _buildSquareActionCard(
          Icons.insert_chart_outlined,
          'View\nGoals',
          Colors.purple,
          widget.onViewGoals,
        ),
        _buildSquareActionCard(
          Icons.water_drop_outlined,
          'Log\nHydration',
          Colors.lightBlue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HydrationScreen()),
            );
          },
        ),
        _buildSquareActionCard(
          Icons.self_improvement_outlined,
          'Start\nMeditation',
          Colors.teal,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MeditationScreen()),
            );
          },
        ),
      ],
    );
  }

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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
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

  Widget _buildAIMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
      ),
      child: Row(
        children: [
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
