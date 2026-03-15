import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

// Base URL for the backend API
final String baseUrl = ApiConstants.baseUrl;

//  DATA MODELS

// Model representing a single exercise within a workout
class ExerciseItem {
  final String id; // Unique identifier for the exercise
  String name; // Name of the exercise (e.g., Squats)
  String muscleGroup; // Targeted muscle group
  List<String> reps; // List storing the number of reps for each set
  String
  restBetweenExercise; // Rest time after completing this specific exercise

  ExerciseItem({
    required this.name,
    required this.muscleGroup,
    required this.reps,
    required this.restBetweenExercise,
  }) : id = UniqueKey().toString(); // Automatically generate a unique key
}

// Model representing a complete workout session
class WorkoutItem {
  String? id; // Database ID (nullable before saving)
  String name; // Name of the workout (e.g., Upper Body)
  DateTime date; // Date when the workout is performed
  List<ExerciseItem> exercises; // List of exercises in this workout
  String globalRestTime; // Default rest time between sets across all exercises
  double rpe; // Rate of Perceived Exertion (1-10 difficulty scale)

  WorkoutItem({
    this.id,
    required this.name,
    required this.date,
    required this.exercises,
    required this.globalRestTime,
    required this.rpe,
  }) {
    id ??= UniqueKey().toString(); // Assign a unique key if no ID is provided
  }
}

//  SCREEN 1: MAIN WORKOUT LIST
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // List holding all saved workouts fetched from the server
  final List<WorkoutItem> _savedWorkouts = [];

  @override
  void initState() {
    super.initState();
    fetchWorkoutData(); // Fetch workouts when the screen loads
  }

  // Method to retrieve workout data from the backend API
  Future<void> fetchWorkoutData() async {
    final url = Uri.parse('$baseUrl/api/get-workout?user_id=1');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        // Map the JSON response into a list of WorkoutItem objects
        List<WorkoutItem> fetchedWorkouts = data.map<WorkoutItem>((item) {
          var exercisesJson = item['exercises'] as List? ?? [];

          // Map the nested JSON exercises into ExerciseItem objects
          List<ExerciseItem> parsedExercises = exercisesJson.map((ex) {
            return ExerciseItem(
              name: ex['exerciseName'] ?? '',
              muscleGroup: ex['muscleGroup'] ?? '',
              reps: (ex['reps'] ?? '').split(
                ',',
              ), // Convert the comma-separated string back into a List of reps
              restBetweenExercise: ex['recoveryExercise']?.toString() ?? '30',
            );
          }).toList();

          return WorkoutItem(
            id: item['id'].toString(),
            name: item['workoutName'] ?? 'Antrenament Necunoscut',
            date: item['date'] != null
                ? DateTime.parse(item['date'])
                : DateTime.now(),
            globalRestTime: item['globalRestTime']?.toString() ?? '60',
            rpe: (item['rpe'] ?? 5.0).toDouble(),
            exercises:
                parsedExercises, // Assign the parsed exercises list to the workout item
          );
        }).toList();

        // Update the UI with the fetched workouts
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

  // Navigate to the form screen to create a new workout or edit an existing one
  void _navigateToLogWorkout({int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogWorkoutScreen(
          workoutToEdit: index != null
              ? _savedWorkouts[index]
              : null, // Pass data if editing
        ),
      ),
    );

    // If a valid WorkoutItem is returned from the form, update the list
    if (result != null && result is WorkoutItem) {
      setState(() {
        if (index != null) {
          _savedWorkouts[index] = result; // Update existing
        } else {
          _savedWorkouts.insert(0, result); // Add new at the top
        }
      });
    }
  }

  // Helper method to format dates nicely (dd.mm.yyyy)
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
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            //  ADD WORKOUT BUTTON
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

            //  WORKOUTS LIST
            Expanded(
              child: _savedWorkouts.isEmpty
                  // Display placeholder message if the list is empty
                  ? const Center(
                      child: Text(
                        'No workouts yet.\nTap "Add Workout" to start!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    )
                  // Display the list of workout cards
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
                                // Header of the card (Title + Action Icons)
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
                                        // Edit Button
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
                                        // Delete Button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () async {
                                            final workoutId = workout.id;

                                            // Delete the workout from the UI immediately
                                            setState(() {
                                              _savedWorkouts.removeAt(index);
                                            });

                                            // Send a delete request to the server to remove it from the database (only if it has a valid ID)
                                            if (workoutId != null &&
                                                !workoutId.contains('#')) {
                                              try {
                                                await http.delete(
                                                  Uri.parse(
                                                    '$baseUrl/api/delete-workout?id=$workoutId',
                                                  ),
                                                );
                                              } catch (e) {
                                                print("Error on delete: $e");
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Date details
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
                                // Footer details (Number of exercises & RPE)
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

//  SCREEN 2: LOG/EDIT A SPECIFIC WORKOUT
class LogWorkoutScreen extends StatefulWidget {
  final WorkoutItem?
  workoutToEdit; // Passed if we are editing an existing workout

  const LogWorkoutScreen({super.key, this.workoutToEdit});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  // Input fields and states for the workout being logged
  final TextEditingController _workoutNameController = TextEditingController();
  List<ExerciseItem> _exercises = [];
  String _globalRestTime = '60'; // Default rest time between sets

  @override
  void initState() {
    super.initState();
    // Pre-fill data if we are editing an existing workout
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

  // Opens a dialog to change the global rest time between sets
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
            // Delete / Clear button
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
            // Save button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _globalRestTime = editController.text;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Navigates to the Add/Edit Exercise screen
  void _navigateToAddExercise({int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(
          exerciseToEdit: index != null ? _exercises[index] : null,
        ),
      ),
    );

    // Updates the exercise list when returning from the form
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

  // Sends the finalized workout data to the backend via POST request
  Future<void> sendWorkoutData(WorkoutItem workout) async {
    final url = Uri.parse('$baseUrl/api/save-workout');

    // Format the exercises list into JSON structure expected by the API
    List<Map<String, dynamic>> exercisesJson = workout.exercises
        .map<Map<String, dynamic>>((ex) {
          return {
            "exerciseName": ex.name,
            "muscleGroup": ex.muscleGroup,
            "sets": ex.reps.length,
            "reps": ex.reps.join(","), // Compress reps array to a single string
            "recoveryBetweenSets": int.tryParse(workout.globalRestTime) ?? 60,
            "recoveryExercise": int.tryParse(ex.restBetweenExercise) ?? 30,
          };
        })
        .toList();

    // Prepare the final payload
    Map<String, dynamic> workoutData = {
      "id": workout.id,
      "user_id": 1,
      "workoutName": workout.name,
      "date": workout.date.toIso8601String(),
      "rpe": workout.rpe,
      "globalRestTime": int.tryParse(workout.globalRestTime) ?? 60,
      "exercises": exercisesJson,
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

  // Shows the RPE (Rate of Perceived Exertion) slider dialog to finalize the workout
  void _showEffortEvaluationDialog() {
    // Validation: Require a workout name before finishing
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
        // StatefulBuilder allows the dialog to update its own state (slider moves)
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            String difficultyTitle = '';
            String difficultyDescription = '';

            // Update description text and colors dynamically based on slider value
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
                  // Dynamic Difficulty Title
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
                  // Dynamic Description
                  Text(
                    difficultyDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // The RPE Slider (1 to 10)
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
                // Finalize and Save Button
                ElevatedButton(
                  onPressed: () {
                    // Create the final WorkoutItem object
                    final finalWorkout = WorkoutItem(
                      id: widget.workoutToEdit?.id,
                      name: _workoutNameController.text,
                      date: widget.workoutToEdit?.date ?? DateTime.now(),
                      exercises: _exercises,
                      globalRestTime: _globalRestTime,
                      rpe: currentSliderValue,
                    );

                    // Send to backend
                    sendWorkoutData(finalWorkout);

                    // Pop dialog, then pop screen, returning the final data to the list
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
      // Set the light gray-white background color
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          widget.workoutToEdit == null ? 'New Workout' : 'Edit Workout',
          // Make the title text bold
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            //  WORKOUT NAME INPUT
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

            //  ADD EXERCISE BUTTON
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
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            const SizedBox(height: 15),

            //  GLOBAL REST TIME INDICATOR/BUTTON
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
                    _globalRestTime = '60'; // Default
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

            //  LIST OF ADDED EXERCISES
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
                            // Trailing Edit & Delete Buttons
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

            //  SAVE WORKOUT BUTTON (Only visible if there are exercises)
            if (_exercises.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _showEffortEvaluationDialog, // Proceeds to RPE
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

//  SCREEN 3: ADD/EDIT A SINGLE EXERCISE
class AddExerciseScreen extends StatefulWidget {
  final ExerciseItem? exerciseToEdit;

  const AddExerciseScreen({super.key, this.exerciseToEdit});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  // Input controllers for the exercise details
  final _exerciseNameController = TextEditingController();
  final _restBetweenExerciseController = TextEditingController();
  final List<TextEditingController> _repsControllers =
      []; // One controller per set

  //  MODIFICATION 1: Available muscle groups for the dropdown
  final List<String> _muscleGroups = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Core',
  ];
  String _selectedMuscleGroup = 'Chest'; // Default selection

  @override
  void initState() {
    super.initState();
    // Pre-fill data if we are editing an existing exercise
    if (widget.exerciseToEdit != null) {
      _exerciseNameController.text = widget.exerciseToEdit!.name;
      _restBetweenExerciseController.text =
          widget.exerciseToEdit!.restBetweenExercise;

      //  MODIFICATION 2: Set the dropdown to the previously saved muscle group
      if (_muscleGroups.contains(widget.exerciseToEdit!.muscleGroup)) {
        _selectedMuscleGroup = widget.exerciseToEdit!.muscleGroup;
      } else {
        _selectedMuscleGroup =
            'Chest'; // Fallback just in case of old/invalid text
      }

      // Populate text controllers for the existing sets
      for (var rep in widget.exerciseToEdit!.reps) {
        _repsControllers.add(TextEditingController(text: rep));
      }
    } else {
      // If adding a new exercise, start with one empty set by default
      _repsControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _restBetweenExerciseController.dispose();
    // Disposal of all dynamic set controllers
    for (var controller in _repsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Method to add a new empty set field to the list
  void _addSet() {
    setState(() {
      _repsControllers.add(TextEditingController());
    });
  }

  // Method to remove a specific set from the list
  void _removeSet(int index) {
    setState(() {
      _repsControllers[index].dispose();
      _repsControllers.removeAt(index);
    });
  }

  // Finalizes the exercise creation and returns to the previous screen
  void _saveExercise() {
    if (_exerciseNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name!')),
      );
      return;
    }

    final newExercise = ExerciseItem(
      name: _exerciseNameController.text,
      muscleGroup:
          _selectedMuscleGroup, //  MODIFICATION 3: Passing the selected dropdown value
      // Extract texts from all set controllers and filter out empty ones
      reps: _repsControllers
          .map((c) => c.text)
          .where((text) => text.isNotEmpty)
          .toList(),
      restBetweenExercise: _restBetweenExerciseController.text,
    );

    Navigator.pop(
      context,
      newExercise,
    ); // Return the object back to the Workout Form
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the consistent light gray-white background color
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          widget.exerciseToEdit == null ? 'Add Exercise' : 'Edit Exercise',
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  EXERCISE DETAILS SECTION
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

            // Dropdown menu to select the Muscle Group
            DropdownButtonFormField<String>(
              initialValue: _selectedMuscleGroup,
              decoration: const InputDecoration(
                labelText: 'Muscle Group',
                border: OutlineInputBorder(),
              ),
              items: _muscleGroups.map((String group) {
                return DropdownMenuItem<String>(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMuscleGroup = newValue;
                  });
                }
              },
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            //  SETS & REPS SECTION
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
            // Dynamically renders the text fields for each set
            ListView.builder(
              shrinkWrap:
                  true, // Prevents scroll conflict with the parent ScrollView
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _repsControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      // Set label (e.g., "Set 1:")
                      Text(
                        'Set ${index + 1}:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Reps input field
                      Expanded(
                        child: TextField(
                          controller: _repsControllers[index],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            border: OutlineInputBorder(),
                            isDense:
                                true, // Makes the field slightly more compact
                          ),
                        ),
                      ),
                      // Delete Set button
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

            //  REST TIME SECTION
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

            //  FINALIZE SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
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
