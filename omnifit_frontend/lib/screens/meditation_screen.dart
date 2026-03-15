import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//  DATA MODELS
// Model representing a single meditation session
class MeditationSession {
  final String id; // Unique identifier for the session
  final int minutes; // Duration of the meditation in minutes
  final String
  time; // Formatted string of when the session was logged (e.g., "14:30")

  MeditationSession({required this.minutes, required this.time})
    : id = UniqueKey()
          .toString(); // Automatically generate a unique key upon creation
}

//  MAIN SCREEN
class MeditationScreen extends StatefulWidget {
  // Constructor
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  //  STATE VARIABLES
  int _dailyGoalMinutes = 30; // Default daily goal: 30 minutes
  final List<MeditationSession> _todaySessions =
      []; // List to store all sessions logged today

  // Calculate total minutes meditated today by summing up the duration of all sessions
  int get _totalMinutesToday =>
      _todaySessions.fold(0, (sum, session) => sum + session.minutes);

  // Calculate the remaining minutes needed to reach the daily goal
  int get _minutesRemaining => _dailyGoalMinutes - _totalMinutesToday;

  // Method to log a new meditation session and update the UI
  void _addMeditationSession(int minutes) {
    setState(() {
      final now = DateTime.now(); // Get current timestamp
      final timeString = DateFormat(
        'HH:mm',
      ).format(now); // Format timestamp to HH:mm

      // Add the new session to the beginning of the list so it appears at the top
      _todaySessions.insert(
        0,
        MeditationSession(minutes: minutes, time: timeString),
      );
    });
  }

  // Show a dialog popup allowing the user to change their daily meditation goal
  void _showSetGoalDialog() {
    final TextEditingController goalController = TextEditingController(
      text: _dailyGoalMinutes.toString(), // Pre-fill with current goal
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Set Daily Goal',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number, // Ensure numeric keyboard
            decoration: const InputDecoration(
              labelText: 'Target (minutes)',
              suffixText: 'min',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            // Save button
            ElevatedButton(
              onPressed: () {
                final newGoal = int.tryParse(goalController.text);
                // Validate input: update goal only if it's a positive number
                if (newGoal != null && newGoal > 0) {
                  setState(() {
                    _dailyGoalMinutes = newGoal;
                  });
                }
                Navigator.pop(context); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Calming teal color
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Method to show a dialog allowing the user to add a custom session duration
  void _showCustomAddDialog() {
    final TextEditingController minutesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add Session',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: minutesController,
            keyboardType: TextInputType.number, // Ensure numeric keyboard
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            // Add button
            ElevatedButton(
              onPressed: () {
                final mins = int.tryParse(minutesController.text);
                // Validate input: log session only if it's a positive number
                if (mins != null && mins > 0) {
                  _addMeditationSession(mins);
                }
                Navigator.pop(context); // Close the dialog
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the progress ratio (between 0.0 and 1.0) for the circular indicator
    double progress = _totalMinutesToday / _dailyGoalMinutes;
    if (progress > 1.0) progress = 1.0; // Cap visual progress at 100%

    // Check if the user has exceeded their daily goal
    bool isExceeded = _minutesRemaining < 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Light greyish-blue background
      appBar: AppBar(
        title: const Text(
          'Mindfulness',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255), 
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0, // Flat app bar
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
                  'Meditation',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                // Button group: Custom Add (+) and Set Goal
                Row(
                  children: [
                    // Square '+' Button (Custom Add)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.teal, // Teal button background
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Rounded corners
                        ),
                        child: IconButton(
                          onPressed:
                              _showCustomAddDialog, // Opens custom add dialog
                          icon: const Icon(Icons.add, size: 20),
                          color: Colors.white,
                          padding: EdgeInsets
                              .zero, // Important for perfect centering in small box
                          constraints:
                              const BoxConstraints(), // Removes default flutter margins
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), // Spacing between buttons
                    // 'Set Goal' Outlined Button
                    OutlinedButton.icon(
                      onPressed: _showSetGoalDialog,
                      icon: const Icon(
                        Icons.adjust,
                        size: 16,
                        color: Colors.teal, // Teal icon
                      ),
                      label: const Text(
                        'Set Goal',
                        style: TextStyle(color: Colors.teal), // Teal text
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Rounded corners
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            //  MAIN PROGRESS CIRCLE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.02,
                    ), // Subtle shadow
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Circular Progress Indicator Container
                  SizedBox(
                    height: 170,
                    width: 170,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // The actual circular progress bar
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 14,
                          backgroundColor: Colors.teal.withValues(
                            alpha: 0.15,
                          ), // Faded teal track
                          valueColor: AlwaysStoppedAnimation<Color>(
                            // Change color to purple if goal is exceeded, else keep teal
                            isExceeded ? Colors.deepPurpleAccent : Colors.teal,
                          ),
                        ),
                        // Data displayed inside the circle
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.self_improvement, // Meditation icon
                                color: Colors.teal.shade300,
                                size: 36,
                              ),
                              const SizedBox(height: 4),
                              // Total minutes achieved
                              Text(
                                '$_totalMinutesToday',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                  height: 1.1,
                                ),
                              ),
                              // Daily Goal text
                              Text(
                                'of $_dailyGoalMinutes min',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Statistics below the circle (Remaining/Extra | Completed %)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Remaining or Extra minutes
                      _buildMiniStat(
                        isExceeded ? 'Extra' : 'Remaining',
                        '${_minutesRemaining.abs()} min',
                        isExceeded ? Colors.deepPurpleAccent : Colors.teal,
                      ),
                      // Vertical divider line
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                      ),
                      // Completion Percentage
                      _buildMiniStat(
                        'Completed',
                        '${(progress * 100).toInt()}%',
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            //  QUICK ACTION BUTTONS
            const Text(
              'Quick Add',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Row of preset duration buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAddButton('+ 5 min', 5, Colors.teal.shade300),
                _buildQuickAddButton('+ 10 min', 10, Colors.teal.shade500),
                _buildQuickAddButton('+ 15 min', 15, Colors.teal.shade700),
              ],
            ),

            const SizedBox(height: 40),

            //  HISTORY SECTION
            const Text(
              "Today's Sessions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            // Show message if no sessions are logged yet
            if (_todaySessions.isEmpty)
              const Text(
                "Take a deep breath. No sessions logged yet today! 🧘‍♀️",
                style: TextStyle(color: Colors.black54, fontSize: 15),
              )
            // Render the list of sessions
            else
              ListView.builder(
                shrinkWrap: true, // Prevents layout errors inside ScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Scroll handled by parent
                itemCount: _todaySessions.length,
                itemBuilder: (context, index) {
                  final session = _todaySessions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ListTile(
                      // Circular icon for each list item
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.spa_rounded,
                          color: Colors.teal,
                        ),
                      ),
                      // Session duration
                      title: Text(
                        "${session.minutes} minutes",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // Subtitle text
                      subtitle: const Text("Mindfulness Practice"),
                      // Timestamp of the session
                      trailing: Text(
                        session.time,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),

            //  TIP BOX
            _buildTipBox(),

            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  // Helper Widget: Builds the Quick Add buttons (+5, +10, +15)
  Widget _buildQuickAddButton(String label, int minutes, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () =>
              _addMeditationSession(minutes), // Logs session on tap
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget: Statistics below the circle (Remaining/Completed)
  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Helper Widget: Information/Tip box with a light background
  Widget _buildTipBox() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08), // Light teal background
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧘‍♂️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Tip: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'Even 5 minutes of meditation can significantly reduce stress and improve your focus throughout the day.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
