import 'package:flutter/material.dart';

class ExerciseItem {
  String name;
  String muscleGroup;
  List<String> reps;
  String restBetweenExercise; 
  String restBetweenSets;    

  ExerciseItem({
    required this.name,
    required this.muscleGroup,
    required this.reps,
    required this.restBetweenExercise,
    this.restBetweenSets = '', 
  });
}


class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final List<ExerciseItem> _exercises = [];
  
  final _betweenSetsController = TextEditingController(text: '60');

  @override
  void dispose() {
    _betweenSetsController.dispose();
    super.dispose();
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
          result.restBetweenSets = _exercises[index].restBetweenSets;
          _exercises[index] = result; 
        } else {
          result.restBetweenSets = _betweenSetsController.text;
          _exercises.add(result); 
        }
      });
    }
  }

  void _showRpeDialog() {
    double currentSliderValue = 5;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String difficultyTitle = '';
            String difficultyDescription = '';

            if (currentSliderValue <= 3) {
              difficultyTitle = 'Easy';
              difficultyDescription = 'Felt like a warm-up. You could easily hold a conversation.';
            } else if (currentSliderValue <= 7) {
              difficultyTitle = 'Medium';
              difficultyDescription = 'Heart rate is up. Breathing is heavier, but you are in control.';
            } else {
              difficultyTitle = 'Hard';
              difficultyDescription = 'Maximum effort! Muscles are burning and you can barely speak.';
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Effort Evaluation (RPE)', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    difficultyTitle,
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: currentSliderValue <= 3 ? Colors.green : (currentSliderValue <= 7 ? Colors.orange : Colors.red),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(difficultyDescription, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 20),
                  Slider(
                    value: currentSliderValue,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: currentSliderValue.round().toString(),
                    activeColor: Colors.blueAccent,
                    onChanged: (double value) {
                      setState(() { currentSliderValue = value; });
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
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Workout completely saved with RPE: ${currentSliderValue.round()}!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Confirm & Save'),
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
        title: const Text('Log Workout'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToAddExercise(),
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _betweenSetsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Between Sets Rest Time (seconds)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
                isDense: true,
              ),
            ),
            const SizedBox(height: 15),
            
            Expanded(
              child: _exercises.isEmpty
                  ? const Center(child: Text('No exercises added yet.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                  : ListView.builder(
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return Column(
                          children: [
                            if (index > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.timer_outlined, color: Colors.orange, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rest: ${exercise.restBetweenSets} sec', 
                                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            
                            Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 5),
                              child: ListTile(
                                title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Muscle: ${exercise.muscleGroup}'),
                                    Text('Sets: ${exercise.reps.length} | Reps: ${exercise.reps.join(", ")}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _navigateToAddExercise(index: index), 
                                ),
                              ),
                            ),
                          ],
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
                  child: OutlinedButton(
                    onPressed: _showRpeDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green, width: 2),
                      foregroundColor: Colors.green,
                    ),
                    child: const Text('Save Workout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      _restBetweenExerciseController.text = widget.exerciseToEdit!.restBetweenExercise;
      
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an exercise name!')));
      return;
    }

    final newExercise = ExerciseItem(
      name: _exerciseNameController.text,
      muscleGroup: _muscleGroupController.text,
      reps: _repsControllers.map((c) => c.text).where((text) => text.isNotEmpty).toList(),
      restBetweenExercise: _restBetweenExerciseController.text,
    );

    Navigator.pop(context, newExercise);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseToEdit == null ? 'Add Exercise' : 'Edit Exercise'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exercise Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            TextField(
              controller: _exerciseNameController,
              decoration: const InputDecoration(labelText: 'Exercise Name (e.g., Squats)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _muscleGroupController,
              decoration: const InputDecoration(labelText: 'Muscle Group (e.g., Legs)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sets & Reps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      Text('Set ${index + 1}:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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

            const Text('Rest Time (seconds)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            TextField(
              controller: _restBetweenExerciseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Between Exercise', border: OutlineInputBorder()),
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveExercise,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                child: const Text('Save Exercise', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}