import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Base URL for API requests
final String baseUrl = 'http://127.0.0.1:8080';

//  DATA MODEL FOR WEEKLY SETS
// Represents a weekly workout goal for a specific muscle group
class WeeklySetGoal {
  final String id;
  String muscleGroup; // E.g., 'Chest', 'Back'
  int targetSets; // How many sets the user wants to achieve
  int completedSets; // How many sets the user has currently completed

  WeeklySetGoal({
    String? id,
    required this.muscleGroup,
    required this.targetSets,
    this.completedSets = 0,
  }) : id =
           id ?? UniqueKey().toString(); // Auto-generate ID if none is provided

  // Converts the object into a JSON map for API communication
  Map<String, dynamic> toJson() => {
    'muscle_group': muscleGroup,
    'target_sets': targetSets,
    'completed_sets': completedSets,
  };
}

//  MAIN SCREEN
class GoalScreen extends StatefulWidget {
  final int userId; // ID of the currently logged-in user
  const GoalScreen({super.key, required this.userId});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  //  STATE VARIABLES
  final List<WeeklySetGoal> _goals =
      []; // Holds the list of goals fetched from the server
  bool _isLoading =
      false; // Indicates if a network request is currently running

  // UI Colors
  static const Color primaryGoalColor = Color.fromARGB(255, 60, 140, 231);
  static const Color addBtnColor = Color(0xFF1565C0);
  static const Color saveBtnColor = Color(0xFF4CAF50);

  bool _showTip = true; // Controls whether the tip box at the bottom is visible
  Timer? _tipTimer; // Timer to auto-hide the tip after a few seconds

  // Available muscle groups for the dropdown menu
  final List<String> _muscleGroups = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Core',
  ];

  @override
  void initState() {
    super.initState();
    fetchGoalsData(); // Load goals when screen opens

    // Hide the tip box after 5 seconds automatically
    _tipTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showTip = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tipTimer
        ?.cancel(); // Cancel the timer if the user leaves the screen before it fires
    super.dispose();
  }

  //  HELPER GETTERS
  // Calculates the overall progress percentage across all goals (0.0 to 1.0)
  double get _calculateProgress {
    if (_goals.isEmpty) return 0.0;
    int totalTarget = _goals.fold(0, (sum, item) => sum + item.targetSets);
    int totalCompleted = _goals.fold(
      0,
      (sum, item) => sum + item.completedSets,
    );

    if (totalTarget == 0) return 0.0;
    return (totalCompleted / totalTarget).clamp(0.0, 1.0);
  }

  // Total target sets across all muscle groups
  int get _totalTargetSets =>
      _goals.fold(0, (sum, item) => sum + item.targetSets);

  // Total completed sets across all muscle groups
  int get _totalCompletedSets =>
      _goals.fold(0, (sum, item) => sum + item.completedSets);

  //  API CALLS
  // Fetch existing goals from the backend
  Future<void> fetchGoalsData() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('$baseUrl/api/goals?user_id=${widget.userId}');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _goals.clear();
            _goals.addAll(
              data.map(
                (item) => WeeklySetGoal(
                  id: item['id']?.toString(),
                  muscleGroup: item['muscleGroup']?.toString() ?? 'Unknown',
                  targetSets: int.tryParse(item['targetSets'].toString()) ?? 0,
                  completedSets:
                      int.tryParse(item['currentSets'].toString()) ?? 0,
                ),
              ),
            );
          });
        }
      }
    } catch (e) {
      print("Error fetching goals: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Save all modified or newly added goals to the backend
  Future<void> _saveAllGoals() async {
    setState(() => _isLoading = true);

    try {
      // Loop through all goals and send a POST request for each
      for (var goal in _goals) {
        final response = await http.post(
          Uri.parse('$baseUrl/api/goals'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": widget.userId,
            "muscleGroup": goal.muscleGroup,
            "targetSets": goal.targetSets,
          }),
        );
        print(
          "Save Goal Response for ${goal.muscleGroup}: ${response.statusCode} | ${response.body}",
        );
      }

      // Refresh data from server to ensure UI is in sync with database
      await fetchGoalsData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goals have been saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error saving goals: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //  DIALOGS
  // Shows a dialog to add a new weekly muscle goal
  void _showAddGoalDialog() {
    // Set the first value in the list as the default selected option
    String? selectedMuscle = _muscleGroups.first;
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // We use StatefulBuilder to be able to call setState ONLY inside the dialog
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add Weekly Goal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //  DROPDOWN FOR MUSCLE GROUPS
                  DropdownButtonFormField<String>(
                    value: selectedMuscle,
                    decoration: const InputDecoration(
                      labelText: 'Muscle Group',
                      border: OutlineInputBorder(),
                    ),
                    items: _muscleGroups.map((String muscle) {
                      return DropdownMenuItem<String>(
                        value: muscle,
                        child: Text(muscle),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      // Update the dialog's local state when a new group is selected
                      setStateDialog(() {
                        selectedMuscle = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Sets per Week',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                // Add Goal Button
                ElevatedButton(
                  onPressed: () {
                    // Check if a muscle group is selected and a target is entered
                    if (selectedMuscle != null &&
                        targetController.text.isNotEmpty) {
                      // Check if a goal for this muscle group already exists to prevent duplicates
                      bool goalExists = _goals.any(
                        (g) => g.muscleGroup == selectedMuscle,
                      );

                      if (goalExists) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'A goal for this muscle group already exists!',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return; // Stop the addition process
                      }

                      // Update the main screen state with the new goal
                      setState(() {
                        _goals.add(
                          WeeklySetGoal(
                            muscleGroup:
                                selectedMuscle!, // Use the value selected in the dropdown
                            targetSets:
                                int.tryParse(targetController.text) ?? 0,
                            completedSets: 0,
                          ),
                        );
                      });
                      Navigator.pop(context); // Close dialog
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: addBtnColor),
                  child: const Text(
                    'Add Goal',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Weekly Goals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  SECTION 1: PROGRESS CARD
            // Displays the overall completion progress
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: primaryGoalColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryGoalColor.withValues(
                      alpha: 0.25,
                    ), // Subtle shadow matching the card
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Sets Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Percentage Text
                      Text(
                        '${(_calculateProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Sets Ratio Text (e.g., 5 / 12 Sets)
                      Text(
                        '$_totalCompletedSets / $_totalTargetSets Sets',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _calculateProgress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            //  SECTION 2: LIST TITLE & ADD BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Muscle Goals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // Refresh Button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: fetchGoalsData,
                      icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 12),
                    // Add Goal Custom Button
                    InkWell(
                      onTap: _showAddGoalDialog,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: addBtnColor, // Dark blue
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: addBtnColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            //  SECTION 3: GOALS LIST WITH ARROWS
            // Displays a scrollable list of all added muscle goals
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        // Check if the goal has been reached
                        bool isCompleted =
                            goal.completedSets >= goal.targetSets &&
                            goal.targetSets > 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            // Show a green border if the goal is completed
                            border: isCompleted
                                ? Border.all(
                                    color: Colors.green.withValues(alpha: 0.5),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Muscle Group Name
                              Expanded(
                                child: Text(
                                  goal.muscleGroup,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              // Completed / Target values
                              Text(
                                '${goal.completedSets} / ${goal.targetSets}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? Colors.green
                                      : Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Increment / Decrement Arrows
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        goal.targetSets++;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.keyboard_arrow_up,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (goal.targetSets > 0) {
                                          goal.targetSets--;
                                        }
                                      });
                                    },
                                    child: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),

                              // Delete Goal Button
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 22,
                                ),
                                onPressed: () =>
                                    setState(() => _goals.removeAt(index)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            //  SECTION 4: SAVE BUTTON
            // Saves all current goals to the database
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAllGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: saveBtnColor, // Nice green color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Goals',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            //  SECTION 5: TIP BOX (Auto-hiding)
            AnimatedSize(
              duration: const Duration(
                milliseconds: 500,
              ), // Smooth collapse animation
              curve: Curves.easeInOut,
              child: _showTip
                  ? Container(
                      margin: const EdgeInsets.only(
                        bottom: 10,
                      ), // Moved margin here inside the container
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Tip: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Your goals will be used to generate personalized recommendations and track your progress.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(), // If false, it takes up no space at all
            ),
          ],
        ),
      ),
    );
  }
}
