import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- MODELE DE DATE ---

class MealItem {
  final String id;
  String name;
  int calories;

  MealItem({required this.name, required this.calories})
    : id = UniqueKey().toString();
}

class NutritionDayItem {
  final String id;
  DateTime date;
  List<MealItem> meals;

  NutritionDayItem({required this.date, required this.meals})
    : id = UniqueKey().toString();

  // Calculează automat totalul de calorii din toate mesele
  int get totalCalories {
    return meals.fold(0, (sum, meal) => sum + meal.calories);
  }
}

// --- ECRAN 1: LISTA DE ZILE (NUTRITION LOG) ---

class NutritionScreen extends StatefulWidget {
  final int userId;
  const NutritionScreen({super.key, required this.userId});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final List<NutritionDayItem> _savedLogs = [];

  @override
  void initState() {
    super.initState();
    fetchNutritionData();
  }

  Future<void> fetchNutritionData() async {
    final url = Uri.parse(
      'http://10.0.2.2:8080/api/get-nutrition?user_id=${widget.userId}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        List<NutritionDayItem> fetchedLogs = data.map<NutritionDayItem>((item) {
          return NutritionDayItem(
            date: item['date'] != null
                ? DateTime.parse(item['date'])
                : DateTime.now(),
            meals:
                <
                  MealItem
                >[], // Aici poți parsa și mesele dacă le returnează serverul
          );
        }).toList();

        setState(() {
          _savedLogs.clear();
          _savedLogs.addAll(fetchedLogs);
        });
        print("Date nutriție încărcate cu succes!");
      } else {
        print("Eroare la server: ${response.statusCode}");
      }
    } catch (e) {
      print("Eroare de conexiune HTTP: $e");
    }
  }

  void _navigateToLogNutrition({int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogNutritionScreen(
          logToEdit: index != null ? _savedLogs[index] : null,
          userId: widget.userId,
        ),
      ),
    );

    if (result != null && result is NutritionDayItem) {
      setState(() {
        if (index != null) {
          _savedLogs[index] = result;
        } else {
          _savedLogs.insert(0, result);
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
        centerTitle: false, // <-- Titlul la stânga
        title: const Text(
          'Nutrition Log',
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
                onPressed: () => _navigateToLogNutrition(),
                icon: const Icon(Icons.add, size: 28),
                label: const Text(
                  'Log New Day',
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
              child: _savedLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No nutrition logs yet.\nTap "Log New Day" to start!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _savedLogs.length,
                      itemBuilder: (context, index) {
                        final log = _savedLogs[index];
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
                                      _formatDate(log.date),
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
                                              _navigateToLogNutrition(
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
                                              _savedLogs.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${log.meals.length} meals logged',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${log.totalCalories} kcal',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
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

// --- ECRAN 2: ADAUGAREA ZILEI ȘI A MESELOR ---

class LogNutritionScreen extends StatefulWidget {
  final NutritionDayItem? logToEdit;
  final int userId;

  const LogNutritionScreen({super.key, this.logToEdit, required this.userId});

  @override
  State<LogNutritionScreen> createState() => _LogNutritionScreenState();
}

class _LogNutritionScreenState extends State<LogNutritionScreen> {
  DateTime _selectedDate = DateTime.now();
  List<MealItem> _meals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.logToEdit != null) {
      _selectedDate = widget.logToEdit!.date;
      _meals = List.from(widget.logToEdit!.meals);
    }
  }

  void _navigateToAddMeal({int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddMealScreen(mealToEdit: index != null ? _meals[index] : null),
      ),
    );

    if (result != null && result is MealItem) {
      setState(() {
        if (index != null) {
          _meals[index] = result;
        } else {
          _meals.add(result);
        }
      });
    }
  }

  Future<void> sendNutritionData(NutritionDayItem dayLog) async {
    setState(() => _isLoading = true);
    final url = Uri.parse(
      'http://10.0.2.2:8080/nutrition',
    ); // Rula serverul lui Răzvan

    Map<String, dynamic> logData = {
      "user_id": widget.userId,
      "calories": dayLog.totalCalories,
      "date": dayLog.date
          .toIso8601String(), // Opțional dacă backendul tău suportă
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(logData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Total calorii salvat cu succes!");
        Navigator.of(context).pop(dayLog);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eroare la salvare. Verifică serverul!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eroare de rețea: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalDayCalories = _meals.fold(0, (sum, meal) => sum + meal.calories);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.logToEdit == null ? 'New Day Log' : 'Edit Day Log'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header: Date and Total Calories
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Today:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$totalDayCalories kcal',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToAddMeal(),
                icon: const Icon(Icons.add),
                label: const Text('Add Meal', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 15),

            Expanded(
              child: _meals.isEmpty
                  ? const Center(
                      child: Text(
                        'No meals added yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _meals.length,
                      itemBuilder: (context, index) {
                        final meal = _meals[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(
                              Icons.restaurant,
                              color: Colors.orange,
                            ),
                            title: Text(
                              meal.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text('${meal.calories} kcal'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _navigateToAddMeal(index: index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _meals.removeAt(index);
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

            if (_meals.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            final finalLog = NutritionDayItem(
                              date: _selectedDate,
                              meals: _meals,
                            );
                            sendNutritionData(finalLog);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Total to Database',
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

// --- ECRAN 3: CREAREA/EDITAREA UNEI MESE INDIVIDUALE ---

class AddMealScreen extends StatefulWidget {
  final MealItem? mealToEdit;

  const AddMealScreen({super.key, this.mealToEdit});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _mealNameController = TextEditingController();
  final _caloriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.mealToEdit != null) {
      _mealNameController.text = widget.mealToEdit!.name;
      _caloriesController.text = widget.mealToEdit!.calories.toString();
    }
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _saveMeal() {
    if (_mealNameController.text.isEmpty || _caloriesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter meal name and calories!')),
      );
      return;
    }

    final newMeal = MealItem(
      name: _mealNameController.text,
      calories: int.tryParse(_caloriesController.text) ?? 0,
    );

    Navigator.pop(context, newMeal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mealToEdit == null ? 'Add Meal' : 'Edit Meal'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meal Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _mealNameController,
              decoration: const InputDecoration(
                labelText: 'Meal Name (e.g., Breakfast, Apple)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories (kcal)',
                border: OutlineInputBorder(),
                suffixText: 'kcal',
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Meal', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
