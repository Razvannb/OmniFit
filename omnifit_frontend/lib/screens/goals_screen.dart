import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

final String baseUrl = 'http://127.0.0.1:8080';

// --- DATA MODEL FOR WEEKLY SETS ---
class WeeklySetGoal {
  final String id;
  String muscleGroup;
  int targetSets;
  int completedSets;

  WeeklySetGoal({
    String? id,
    required this.muscleGroup,
    required this.targetSets,
    this.completedSets = 0,
  }) : id = id ?? UniqueKey().toString();

  Map<String, dynamic> toJson() => {
    'muscle_group': muscleGroup,
    'target_sets': targetSets,
    'completed_sets': completedSets,
  };
}

// --- MAIN SCREEN ---
class GoalScreen extends StatefulWidget {
  final int userId;
  const GoalScreen({super.key, required this.userId});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final List<WeeklySetGoal> _goals = [];
  bool _isLoading = false;

  static const Color primaryGoalColor = Color.fromARGB(255, 60, 140, 231);
  static const Color addBtnColor = Color(0xFF1565C0);
  static const Color saveBtnColor = Color(0xFF4CAF50);

  bool _showTip = true; // controlls if the tip box is visible
  Timer? _tipTimer; // timer to auto-hide the tip after a few seconds

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
    fetchGoalsData();
    // hide the tip box after 5 seconds
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
    _tipTimer?.cancel();
    super.dispose();
  }

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

  int get _totalTargetSets =>
      _goals.fold(0, (sum, item) => sum + item.targetSets);
  int get _totalCompletedSets =>
      _goals.fold(0, (sum, item) => sum + item.completedSets);

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
      print("Eroare la preluarea obiectivelor: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAllGoals() async {
    setState(() => _isLoading = true);

    try {
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
          "Save Goal Response pt ${goal.muscleGroup}: ${response.statusCode} | ${response.body}",
        );
      }

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
      print("Eroare la salvarea obiectivelor: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddGoalDialog() {
    // Setăm prima valoare din listă ca fiind cea selectată default
    String? selectedMuscle = _muscleGroups.first;
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // Folosim StatefulBuilder ca să putem face setState DOAR în interiorul dialogului
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
                  // --- AICI ESTE NOUL DROPDOWN PENTRU GRUPE MUSCULARE ---
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
                      // Actualizăm starea dialogului când alegem o altă grupă
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Verificăm dacă a selectat ceva și dacă a introdus target-ul
                    if (selectedMuscle != null &&
                        targetController.text.isNotEmpty) {
                      // Opțional: Verificăm dacă nu cumva există deja un goal pentru grupa asta
                      bool goalExists = _goals.any(
                        (g) => g.muscleGroup == selectedMuscle,
                      );

                      if (goalExists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'A goal for this muscle group already exists!',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return; // Oprim adăugarea
                      }

                      setState(() {
                        _goals.add(
                          WeeklySetGoal(
                            muscleGroup:
                                selectedMuscle!, // Folosim valoarea din dropdown
                            targetSets:
                                int.tryParse(targetController.text) ?? 0,
                            completedSets: 0,
                          ),
                        );
                      });
                      Navigator.pop(context);
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
            // --- SECTION 1: PROGRESS CARD ---
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
                    ), // <-- Actualizat
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
                      Text(
                        '${(_calculateProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _calculateProgress,
                      backgroundColor: Colors.white.withValues(
                        alpha: 0.3,
                      ), // <-- Actualizat
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

            // --- SECTION 2: LIST TITLE & ADD BUTTON IN BODY ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Muscle Goals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: fetchGoalsData,
                      icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _showAddGoalDialog,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: addBtnColor, // <-- Albastru închis
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

            // --- SECTION 3: GOALS LIST WITH ARROWS ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
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
                                color: Colors.black.withValues(
                                  alpha: 0.04,
                                ), // <-- Actualizat
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: isCompleted
                                ? Border.all(
                                    color: Colors.green.withValues(alpha: 0.5),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
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

            // --- SECTION 4: SAVE BUTTON ---
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAllGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: saveBtnColor, // <-- Verde drăguț
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

            // --- SECTION 5: TIP BOX ---
            AnimatedSize(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: _showTip
                  ? Container(
                      margin: const EdgeInsets.only(
                        bottom: 10,
                      ), // mutat marginea aici
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
                  : const SizedBox.shrink(), // Dacă e false, nu ocupă spațiu deloc
            ),
          ],
        ),
      ),
    );
  }
}
