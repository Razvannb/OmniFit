import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExerciseItem {
  final String id;
  String name;
  String muscleGroup;
  List<String> reps;
  String restBetweenExercise;

  ExerciseItem({
    required this.name,
    required this.muscleGroup,
    required this.reps,
    required this.restBetweenExercise,
  }) : id = UniqueKey().toString();
}

class WorkoutItem {
  final String id;
  String name;
  DateTime date;
  List<ExerciseItem> exercises;
  String globalRestTime;
  double rpe;

  WorkoutItem({
    required this.name,
    required this.date,
    required this.exercises,
    required this.globalRestTime,
    required this.rpe,
  }) : id = UniqueKey().toString();
}

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final List<WorkoutItem> _savedWorkouts = [];

  @override
  void initState() {
    super.initState();
    fetchWorkoutData();
  }

Future<void> fetchWorkoutData() async {
    final url = Uri.parse('http://192.168.171.172:8080/api/get-workout');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        
        List<WorkoutItem> fetchedWorkouts = data.map<WorkoutItem>((item) {
          return WorkoutItem(
            name: item['workoutName'] ?? 'Antrenament Necunoscut',
            date: item['date'] != null ? DateTime.parse(item['date']) : DateTime.now(),
            globalRestTime: item['globalRestTime']?.toString() ?? '60',
            rpe: (item['rpe'] ?? 5.0).toDouble(),
            exercises: <ExerciseItem>[], 
          );
        }).toList();

        setState(() {
          _savedWorkouts.clear();
          _savedWorkouts.addAll(fetchedWorkouts);
        });
        
        print("Date încărcate cu succes de pe server!");
      } else {
        print("Eroare la server: ${response.statusCode}");
      }
    } catch (e) {
      print("Eroare de conexiune HTTP: $e");
    }
  }

  void _navigateToLogWorkout({int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogWorkoutScreen(
          workoutToEdit: index != null ? _savedWorkouts[index] : null,
        ),
      ),
    );

    if (result != null && result is WorkoutItem) {
      setState(() {
        if (index != null) {
          _savedWorkouts[index] = result;
        } else {
          _savedWorkouts.insert(0, result);
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Workouts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToLogWorkout(),
                icon: const Icon(Icons.add, size: 28),
                label: const Text(
                  'Add Workout',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _savedWorkouts.isEmpty
                  ? const Center(
                      child: Text(
                        'No workouts yet.\nTap "Add Workout" to start!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _savedWorkouts.length,
                      itemBuilder: (context, index) {
                        final workout = _savedWorkouts[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: const EdgeInsets.only(bottom: 15),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      workout.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blueAccent,
                                          ),
                                          onPressed: () =>
                                              _navigateToLogWorkout(
                                                index: index,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _savedWorkouts.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatDate(workout.date),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${workout.exercises.length} exercises',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'RPE: ${workout.rpe.round()}/10',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class LogWorkoutScreen extends StatefulWidget {
  final WorkoutItem? workoutToEdit;

  const LogWorkoutScreen({super.key, this.workoutToEdit});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  final TextEditingController _workoutNameController = TextEditingController();
  List<ExerciseItem> _exercises = [];
  String _globalRestTime = '60';

  @override
  void initState() {
    super.initState();
    if (widget.workoutToEdit != null) {
      _workoutNameController.text = widget.workoutToEdit!.name;
      _globalRestTime = widget.workoutToEdit!.globalRestTime;
      _exercises = List.from(widget.workoutToEdit!.exercises);
    }
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    super.dispose();
  }

  void _editGlobalRestTime() {
    TextEditingController editController = TextEditingController(
      text: _globalRestTime,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Between Sets Rest Time'),
          content: TextField(
            controller: editController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Seconds',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _globalRestTime = '';
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _globalRestTime = editController.text;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddExercise({int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(
          exerciseToEdit: index != null ? _exercises[index] : null,
        ),
      ),
    );

    if (result != null && result is ExerciseItem) {
      setState(() {
        if (index != null) {
          _exercises[index] = result;
        } else {
          _exercises.add(result);
        }
      });
    }
  }

  Future<void> sendWorkoutData(WorkoutItem workout) async {
    final url = Uri.parse('http://192.168.171.172:8080/api/save-workout');

    List<Map<String, dynamic>> exercisesJson = workout.exercises.map<Map<String, dynamic>>((ex) {
      return {
        "exerciseName": ex.name,
        "muscleGroup": ex.muscleGroup,
        "sets": ex.reps.length,
        "reps": ex.reps.join(","), 
        "recoveryBetweenSets": int.tryParse(workout.globalRestTime) ?? 60,
        "recoveryExercise": int.tryParse(ex.restBetweenExercise) ?? 30,
      };
    }).toList();

    Map<String, dynamic> workoutData = {
      "workoutName": workout.name,
      "date": workout.date.toIso8601String(), 
      "rpe": workout.rpe,
      "globalRestTime": int.tryParse(workout.globalRestTime) ?? 60,
      "exercises": exercisesJson 
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(workoutData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Antrenament trimis la server cu succes!");
      } else {
        print("Eroare la salvare: ${response.statusCode}");
      }
    } catch (e) {
      print("Eroare de conexiune POST: $e");
    }
  }

  void _showEffortEvaluationDialog() {
    if (_workoutNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Workout Name!')),
      );
      return;
    }

    double currentSliderValue = widget.workoutToEdit?.rpe ?? 5.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            String difficultyTitle = '';
            String difficultyDescription = '';

            if (currentSliderValue <= 3) {
              difficultyTitle = 'Easy';
              difficultyDescription =
                  'Felt like a warm-up. You could easily hold a conversation.';
            } else if (currentSliderValue <= 7) {
              difficultyTitle = 'Medium';
              difficultyDescription =
                  'Heart rate is up. Breathing is heavier, but you are in control.';
            } else {
              difficultyTitle = 'Hard';
              difficultyDescription =
                  'Maximum effort! Muscles are burning and you can barely speak.';
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                'Effort Evaluation',
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    difficultyTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: currentSliderValue <= 3
                          ? Colors.green
                          : (currentSliderValue <= 7
                                ? Colors.orange
                                : Colors.red),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    difficultyDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: currentSliderValue,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: currentSliderValue.round().toString(),
                    activeColor: Colors.blueAccent,
                    onChanged: (double value) {
                      setStateDialog(() {
                        currentSliderValue = value;
                      });
                    },
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('10', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final finalWorkout = WorkoutItem(
                      name: _workoutNameController.text,
                      date: widget.workoutToEdit?.date ?? DateTime.now(),
                      exercises: _exercises,
                      globalRestTime: _globalRestTime,
                      rpe: currentSliderValue,
                    );

                    sendWorkoutData(finalWorkout);

                    Navigator.of(context).pop();
                    Navigator.of(context).pop(finalWorkout);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout saved successfully!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save & Finish'),
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
      appBar: AppBar(
        title: Text(
          widget.workoutToEdit == null ? 'New Workout' : 'Edit Workout',
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _workoutNameController,
              decoration: const InputDecoration(
                labelText: 'Workout Name (e.g., Upper Body Push)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToAddExercise(),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Exercise',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 15),

            if (_globalRestTime.isNotEmpty && _globalRestTime != '0')
              InkWell(
                onTap: _editGlobalRestTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rest Between Sets: $_globalRestTime sec',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.edit, color: Colors.orange, size: 18),
                    ],
                  ),
                ),
              )
            else
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _globalRestTime = '60';
                  });
                  _editGlobalRestTime();
                },
                icon: const Icon(Icons.add_alarm, color: Colors.blueAccent),
                label: const Text(
                  'Add Rest Time Between Sets',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                ),
              ),

            const SizedBox(height: 15),

            Expanded(
              child: _exercises.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises added yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(
                              exercise.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Muscle: ${exercise.muscleGroup}'),
                                Text(
                                  'Sets: ${exercise.reps.length} | Reps: ${exercise.reps.join(", ")}',
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _navigateToAddExercise(index: index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _exercises.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (_exercises.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _showEffortEvaluationDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Save Workout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AddExerciseScreen extends StatefulWidget {
  final ExerciseItem? exerciseToEdit;

  const AddExerciseScreen({super.key, this.exerciseToEdit});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _exerciseNameController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _restBetweenExerciseController = TextEditingController();

  final List<TextEditingController> _repsControllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.exerciseToEdit != null) {
      _exerciseNameController.text = widget.exerciseToEdit!.name;
      _muscleGroupController.text = widget.exerciseToEdit!.muscleGroup;
      _restBetweenExerciseController.text =
          widget.exerciseToEdit!.restBetweenExercise;

      for (var rep in widget.exerciseToEdit!.reps) {
        _repsControllers.add(TextEditingController(text: rep));
      }
    } else {
      _repsControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _muscleGroupController.dispose();
    _restBetweenExerciseController.dispose();
    for (var controller in _repsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    setState(() {
      _repsControllers.add(TextEditingController());
    });
  }

  void _removeSet(int index) {
    setState(() {
      _repsControllers[index].dispose();
      _repsControllers.removeAt(index);
    });
  }

  void _saveExercise() {
    if (_exerciseNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name!')),
      );
      return;
    }

    final newExercise = ExerciseItem(
      name: _exerciseNameController.text,
      muscleGroup: _muscleGroupController.text,
      reps: _repsControllers
          .map((c) => c.text)
          .where((text) => text.isNotEmpty)
          .toList(),
      restBetweenExercise: _restBetweenExerciseController.text,
    );

    Navigator.pop(context, newExercise);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exerciseToEdit == null ? 'Add Exercise' : 'Edit Exercise',
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exercise Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _exerciseNameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name (e.g., Squats)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _muscleGroupController,
              decoration: const InputDecoration(
                labelText: 'Muscle Group (e.g., Legs)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sets & Reps',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addSet,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Set'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _repsControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Text(
                        'Set ${index + 1}:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: _repsControllers[index],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeSet(index),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Rest Time (seconds)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _restBetweenExerciseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Between Exercise',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Save Exercise',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
