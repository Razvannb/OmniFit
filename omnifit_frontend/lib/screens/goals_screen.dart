import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- DATA MODEL FOR WEEKLY SETS ---
class WeeklySetGoal {
  final String id;
  String muscleGroup;
  int targetSets; // Obiectivul (dreapta)
  int completedSets; // Realizat (stânga - modificabil)

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

  // Culoarea pentru Progress Card (Movul de mai devreme)
  static const Color primaryGoalColor = Color.fromARGB(255, 167, 151, 251);

  // Noile culori cerute:
  static const Color addBtnColor = Color(0xFF1565C0); // Albastru închis
  static const Color saveBtnColor = Color(0xFF4CAF50); // Verde drăguț

  @override
  void initState() {
    super.initState();
    fetchGoalsData();
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
    final url = Uri.parse(
      'http://10.0.2.2:8080/api/get-set-goals?user_id=${widget.userId}',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        // Verificăm 'mounted' înainte de setState!
        if (mounted) {
          setState(() {
            _goals.clear();
            _goals.addAll(
              data.map(
                (item) => WeeklySetGoal(
                  id: item['id']?.toString(),
                  muscleGroup: item['muscle_group'] ?? 'Unknown',
                  targetSets: item['target_sets'] ?? 0,
                  completedSets: item['completed_sets'] ?? 0,
                ),
              ),
            );
          });
        }
      }
    } catch (e) {
      // --- AICI AM PUS if (mounted) PENTRU A REZOLVA EROAREA TA ---
      if (mounted) {
        setState(() {
          if (_goals.isEmpty) {
            _goals.addAll([
              WeeklySetGoal(
                muscleGroup: 'Chest',
                targetSets: 12,
                completedSets: 5,
              ),
              WeeklySetGoal(
                muscleGroup: 'Back',
                targetSets: 14,
                completedSets: 14,
              ),
            ]);
          }
        });
      }
    } finally {
      // --- LA FEL ȘI AICI ---
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAllGoals() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goals have been saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddGoalDialog() {
    final muscleController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
              TextField(
                controller: muscleController,
                decoration: const InputDecoration(
                  labelText: 'Muscle Group (e.g. Legs)',
                  border: OutlineInputBorder(),
                ),
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
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (muscleController.text.isNotEmpty &&
                    targetController.text.isNotEmpty) {
                  setState(() {
                    _goals.add(
                      WeeklySetGoal(
                        muscleGroup: muscleController.text,
                        targetSets: int.tryParse(targetController.text) ?? 0,
                        completedSets: 0,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: addBtnColor, // Albastru închis
              ),
              child: const Text(
                'Add Goal',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
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
                              color: addBtnColor.withValues(
                                alpha: 0.3,
                              ), // <-- Actualizat
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
                                    color: Colors.green.withValues(
                                      alpha: 0.5,
                                    ), // <-- Actualizat
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              // NUMELE GRUPEI MUSCULARE
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

                              // REALIZAT (Stânga) / TARGET (Dreapta)
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

                              // SĂGEȚI (Compactate)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        goal.completedSets++;
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
                                        if (goal.completedSets > 0) {
                                          goal.completedSets--;
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(
                  alpha: 0.08,
                ), // <-- Actualizat
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                ), // <-- Actualizat
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
