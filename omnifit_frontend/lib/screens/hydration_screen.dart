import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Base URL for API requests (Localhost pointing to backend)
final String baseUrl = 'http://127.0.0.1:8080';

//  MAIN SCREEN
class HydrationScreen extends StatefulWidget {
  final int userId;

  // The constructor
  // [super.key] uniquely identifies this widget in the widget tree for efficient rendering
  // Added userId with a default value of 1 so it doesn't break navigation from Dashboard
  const HydrationScreen({super.key, this.userId = 1});

  // Creates the mutable state for this screen, which will hold the current water intake, daily goal, history of intake, and reminder status
  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  //  STATE VARIABLES
  int currentIntake = 0; // Current amount of water consumed (in ml)
  int dailyGoal = 2500; // Target amount of water to consume daily (in ml)
  List<Map<String, String>> history =
      []; // List to store the log of water intake (amount and time)
  bool isReminderOn = false; // Toggle state for hydration reminders

  @override
  void initState() {
    super.initState();
    fetchHydrationData(); // Load data from backend when screen initializes
  }

  // Fetch data from backend
  Future<void> fetchHydrationData() async {
    try {
      // 1. Fetch Hydration Goal
      final goalRes = await http.get(
        Uri.parse('$baseUrl/api/hydration-goal?user_id=${widget.userId}'),
      );
      if (goalRes.statusCode == 200) {
        final goalData = json.decode(goalRes.body);
        if (mounted) {
          setState(() {
            dailyGoal = goalData['daily_water_goal'] ?? 2500;
          });
        }
      }

      // 2. Fetch Hydration Logs for Today
      final logRes = await http.get(
        Uri.parse('$baseUrl/api/hydration?user_id=${widget.userId}'),
      );
      if (logRes.statusCode == 200) {
        List<dynamic> data = json.decode(logRes.body);

        int calculatedIntake = 0;
        List<Map<String, String>> loadedHistory = [];
        final now = DateTime.now();

        for (var item in data) {
          DateTime logDate = DateTime.parse(item['date']).toLocal();

          // Check if the log belongs to today
          if (logDate.year == now.year &&
              logDate.month == now.month &&
              logDate.day == now.day) {
            int amount = item['amount'] as int;
            calculatedIntake += amount;

            // Format strings for UI
            String timeString =
                '${logDate.hour.toString().padLeft(2, '0')}:${logDate.minute.toString().padLeft(2, '0')}';
            String logAmount = amount > 0 ? '+$amount ml' : '$amount ml';

            loadedHistory.add({'amount': logAmount, 'time': timeString});
          }
        }

        if (mounted) {
          setState(() {
            currentIntake = calculatedIntake < 0 ? 0 : calculatedIntake;
            history = loadedHistory;
          });
        }
      }
    } catch (e) {
      print("Error fetching hydration data: $e");
    }
  }

  // Method to update the water intake and log the entry in backend
  Future<void> _updateWater(int amount) async {
    int actualAmountToAdd = amount;
    int expectedIntake = currentIntake + amount;

    // Prevent the intake from dropping below zero locally and on backend
    if (expectedIntake < 0) {
      actualAmountToAdd = -currentIntake; // Subtract only what is left
    }

    if (actualAmountToAdd != 0) {
      // 1. Update UI Optimistically
      setState(() {
        currentIntake += actualAmountToAdd;
        final now =
            DateTime.now(); // The current time is captured to log when the water intake was updated

        // Format the time as HH:MM (e.g., 08:05)
        final timeString =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        // Format the amount string (e.g., "+250 ml" or "-250 ml")
        String logAmount = actualAmountToAdd > 0
            ? '+$actualAmountToAdd ml'
            : '$actualAmountToAdd ml';

        // Insert at index 0 to keep the most recent logs at the top of the list
        history.insert(0, {'amount': logAmount, 'time': timeString});
      });

      // 2. POST to Backend
      try {
        await http.post(
          Uri.parse('$baseUrl/api/hydration'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": widget.userId,
            "amount": actualAmountToAdd,
            "date": DateTime.now().toIso8601String(),
          }),
        );
      } catch (e) {
        print("Error saving water log: $e");
      }
    }
  }

  // Show a dialog popup allowing the user to change their daily water goal
  void _showSetGoalDialog() {
    final TextEditingController goalController = TextEditingController(
      text: dailyGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Setează Scopul Zilnic', // "Set Daily Goal"
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target (ml)',
              suffixText: 'ml',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Anulează', // "Cancel"
                style: TextStyle(color: Colors.grey),
              ),
            ),
            // Save Button
            ElevatedButton(
              onPressed: () async {
                final newGoal = int.tryParse(goalController.text);

                // Pop the dialog immediately for better UX
                Navigator.pop(context);

                // Validate input and update goal if valid
                if (newGoal != null && newGoal > 0) {
                  setState(() {
                    dailyGoal = newGoal;
                  });

                  // POST Goal to Backend
                  try {
                    await http.post(
                      Uri.parse('$baseUrl/api/hydration-goal'),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "user_id": widget.userId,
                        "daily_water_goal": newGoal,
                      }),
                    );
                  } catch (e) {
                    print("Error saving hydration goal: $e");
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
              ),
              child: const Text(
                'Salvează', // "Save"
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Temporary function for the "+" button in the header
  void _quickAddWater() {
    _updateWater(250); // Example: quickly adds a glass of water (250ml)
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the progress ratio (between 0.0 and 1.0) for the circular indicator
    double progress = dailyGoal == 0 ? 0 : currentIntake / dailyGoal;
    if (progress > 1.0) progress = 1.0; // Cap the visual progress at 100%

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light greyish-blue background
      appBar: AppBar(
        title: const Text(
          'Log Hydration',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        // The 'Set Goal' button was removed from actions as it's now in the body.
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  HEADER ROW: Title and Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hydration', // Fixed typo
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                // Button group: Quick Add (+) and Set Goal
                Row(
                  children: [
                    // Square '+' Button (Quick Add)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(64, 137, 247, 1), // Blue
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: _quickAddWater,
                          icon: const Icon(Icons.add, size: 20),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 'Set Goal' Outlined Button
                    OutlinedButton.icon(
                      onPressed: _showSetGoalDialog,
                      icon: const Icon(Icons.adjust, size: 16),
                      label: const Text('Set Goal'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            //  MAIN PROGRESS CIRCLE
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The actual circular progress bar
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 16,
                      backgroundColor: Colors.lightBlue.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.lightBlue,
                      ),
                    ),
                    // Data displayed inside the circle
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.water_drop,
                            color: Colors.lightBlue.shade300,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          // Current Intake amount
                          Text(
                            '$currentIntake',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          // Daily Goal amount
                          Text(
                            '/ $dailyGoal ml',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),

            //  QUICK ACTION BUTTONS (+ / - water)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterButton(
                  '-250 ml',
                  () => _updateWater(-250),
                  Colors.redAccent.withValues(alpha: 0.8),
                ),
                _buildWaterButton(
                  '+250 ml',
                  () => _updateWater(250),
                  Colors.lightBlue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterButton(
                  '+500 ml',
                  () => _updateWater(500),
                  Colors.blue,
                ),
                _buildWaterButton(
                  '+1000 ml',
                  () => _updateWater(1000),
                  Colors.blue.shade700,
                ),
              ],
            ),

            const SizedBox(height: 40),
            const Divider(),

            //  HISTORY SECTION
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'History Today',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Display friendly message if history is empty
            if (history.isEmpty)
              const Text(
                'No water logged yet today. Time for a glass! 💧',
                style: TextStyle(color: Colors.black54),
              )
            // Otherwise, render the list of logs
            else
              ListView.builder(
                shrinkWrap:
                    true, // Needed to embed ListView inside SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Scroll handled by parent
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  // Determine if the log was adding or removing water
                  final isPositive = item['amount']!.startsWith('+');

                  return ListTile(
                    leading: Icon(
                      isPositive
                          ? Icons
                                .water_drop // Water drop icon for additions
                          : Icons
                                .remove_circle_outline, // Minus icon for removals
                      color: isPositive ? Colors.lightBlue : Colors.redAccent,
                    ),
                    title: Text(
                      item['amount']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      item['time']!,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),

            const SizedBox(height: 24),
            const Divider(),

            //  REMINDER SETTINGS (Toggle)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Memento', // "Reminder"
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Remind me to stay hydrated every hour!'),
              value: isReminderOn,
              activeThumbColor: Colors.lightBlue,
              onChanged: (bool value) {
                // Update state when switch is toggled
                setState(() {
                  isReminderOn = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Builds a styled button for adding/removing water
  Widget _buildWaterButton(String label, VoidCallback onTap, Color color) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
