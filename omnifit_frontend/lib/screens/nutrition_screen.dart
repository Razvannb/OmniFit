import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Base URL for API requests (Localhost pointing to backend)
final String baseUrl = 'http://127.0.0.1:8080';

//  DATA MODELS
// Model representing a single meal
class MealItem {
  final String id;
  String name;
  int calories;
  int proteins;
  int carbs;
  int fats;

  MealItem({
    required this.name,
    required this.calories,
    this.proteins = 0,
    this.carbs = 0,
    this.fats = 0,
  }) : id = UniqueKey().toString(); // Automatically generate a unique ID
}

// Model representing a whole day of nutrition logs
class NutritionDayItem {
  final String id;
  DateTime date;
  List<MealItem> meals;

  NutritionDayItem({required this.date, required this.meals})
    : id = UniqueKey().toString(); // Automatically generate a unique ID

  // Calculate daily totals by summing up all meals
  int get totalCalories => meals.fold(0, (sum, meal) => sum + meal.calories);
  int get totalProteins => meals.fold(0, (sum, meal) => sum + meal.proteins);
  int get totalCarbs => meals.fold(0, (sum, meal) => sum + meal.carbs);
  int get totalFats => meals.fold(0, (sum, meal) => sum + meal.fats);
}

//  SCREEN 1: MAIN NUTRITION LOG
class NutritionScreen extends StatefulWidget {
  final int userId;
  const NutritionScreen({super.key, required this.userId});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final List<NutritionDayItem> _savedLogs = []; // List of all saved daily logs
  int _dailyCalorieGoal = 2400; // Default calorie goal

  @override
  void initState() {
    super.initState();
    fetchNutritionData(); // Load data when screen initializes
  }

  // Helper method to get the log entry for the current day
  NutritionDayItem? get _todayLog {
    final now = DateTime.now();
    try {
      return _savedLogs.firstWhere(
        (log) =>
            log.date.year == now.year &&
            log.date.month == now.month &&
            log.date.day == now.day,
      );
    } catch (e) {
      return null; // Return null if no log exists for today
    }
  }

  // Derived properties for UI display
  int get _caloriesConsumedToday => _todayLog?.totalCalories ?? 0;
  int get _caloriesRemaining => _dailyCalorieGoal - _caloriesConsumedToday;
  double get _progressPercentage => _dailyCalorieGoal == 0
      ? 0.0
      : (_caloriesConsumedToday / _dailyCalorieGoal).clamp(0.0, 1.0);

  // Fetch data from backend
  Future<void> fetchNutritionData() async {
    try {
      // 1. Fetch Calorie Goal
      final goalRes = await http.get(
        Uri.parse('$baseUrl/api/nutrition-goal?user_id=${widget.userId}'),
      );
      if (goalRes.statusCode == 200) {
        final goalData = json.decode(goalRes.body);
        if (mounted) {
          setState(() {
            _dailyCalorieGoal = goalData['daily_calorie_goal'] ?? 2400;
          });
        }
      }

      // 2. Fetch Nutrition Logs
      final response = await http.get(
        Uri.parse('$baseUrl/api/nutrition?user_id=${widget.userId}'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Group meals by date
        Map<String, List<MealItem>> groupedMeals = {};

        for (var item in data) {
          // Extract just the date part (YYYY-MM-DD)
          String dateStr = item['date'].toString().split('T')[0];

          if (!groupedMeals.containsKey(dateStr)) {
            groupedMeals[dateStr] = [];
          }

          groupedMeals[dateStr]!.add(
            MealItem(
              name: item['meal_name'] ?? 'Meal',
              calories: item['calories'] ?? 0,
              proteins: item['proteins'] ?? 0,
              carbs: item['carbs'] ?? 0,
              fats: item['fats'] ?? 0,
            ),
          );
        }

        List<NutritionDayItem> fetchedLogs = [];
        groupedMeals.forEach((dateStr, meals) {
          fetchedLogs.add(
            NutritionDayItem(date: DateTime.parse(dateStr), meals: meals),
          );
        });

        // Sort descending by date
        fetchedLogs.sort((a, b) => b.date.compareTo(a.date));

        if (mounted) {
          setState(() {
            _savedLogs.clear();
            _savedLogs.addAll(fetchedLogs);
          });
        }
      }
    } catch (e) {
      print("Error fetching nutrition data: $e");
    }
  }

  // Displays an alert dialog to change the daily calorie target
  void _showEditGoalDialog() {
    final controller = TextEditingController(
      text: _dailyCalorieGoal.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Set Daily Goal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Goal (kcal)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              int newGoal = int.tryParse(controller.text) ?? 2400;

              // Update goal and close dialog
              setState(() => _dailyCalorieGoal = newGoal);
              Navigator.pop(context);

              // POST goal to backend
              try {
                await http.post(
                  Uri.parse('$baseUrl/api/nutrition-goal'),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "user_id": widget.userId,
                    "daily_calorie_goal": newGoal,
                  }),
                );
              } catch (e) {
                print("Error saving goal: $e");
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isExceeded = _caloriesRemaining < 0; // Check if user went over goal

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Nutrition Log',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  HEADER ROW: Title and Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Calories',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                // Button group: "Add Meal" (+) and "Set Goal"
                Row(
                  children: [
                    // Square '+' Button
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0), // Dark blue
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: _navigateToLogNutrition,
                          icon: const Icon(Icons.add, size: 20),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 'Set Goal' Button
                    OutlinedButton.icon(
                      onPressed: _showEditGoalDialog,
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
            const SizedBox(height: 20),

            //  MAIN PROGRESS CIRCLE CARD
            _buildCalorieProgressCard(isExceeded),
            const SizedBox(height: 25),

            //  MACRONUTRIENTS ROW CARD
            _buildMacronutrientsCard(),
            const SizedBox(height: 35),

            //  HISTORY SECTION
            const Text(
              "History",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildHistoryList(),

            //  TIP/ADVICE BOX
            _buildTipBox(),

            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  // Widget: Information box with a light blue background
  Widget _buildTipBox() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
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
                        'Maintain a balanced intake of macronutrients for optimal results in muscle growth and recovery.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget: The large circular progress indicator showing calories
  Widget _buildCalorieProgressCard(bool isExceeded) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            width: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _progressPercentage,
                  strokeWidth: 14,
                  backgroundColor: Colors.grey.shade100,
                  // Color turns red if goal is exceeded, otherwise blue
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isExceeded ? Colors.redAccent : Colors.blueAccent,
                  ),
                ),
                // Text inside the circle
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_caloriesConsumedToday',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'of $_dailyCalorieGoal kcal',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Statistics below the circle (Remaining | Consumed %)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniStat(
                isExceeded ? 'Exceeded' : 'Remaining',
                '${_caloriesRemaining.abs()}',
                isExceeded ? Colors.redAccent : Colors.blueAccent,
              ),
              // Vertical divider line
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 30),
              ),
              _buildMiniStat(
                'Consumed',
                '${(_progressPercentage * 100).toInt()}%',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget: Displays Proteins, Carbs, and Fats in colored circles
  Widget _buildMacronutrientsCard() {
    final log = _todayLog;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Macronutrients',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroCircle(
                'Proteins',
                '${log?.totalProteins ?? 0}g',
                const Color(0xFFFFE5E5), // Light red background
                Colors.red.shade700,
              ),
              _buildMacroCircle(
                'Carbs',
                '${log?.totalCarbs ?? 0}g',
                const Color(0xFFE5F0FF), // Light blue background
                Colors.blue.shade700,
              ),
              _buildMacroCircle(
                'Fats',
                '${log?.totalFats ?? 0}g',
                const Color(0xFFFFF9E5), // Light yellow/orange background
                Colors.orange.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget to build individual macronutrient circles
  Widget _buildMacroCircle(
    String label,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    return Column(
      children: [
        Container(
          height: 75,
          width: 75,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Helper widget for the text stats (Remaining/Consumed)
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

  // Navigation to the detailed day log view
  void _navigateToLogNutrition() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the meals already logged today to the next screen!
        builder: (context) => LogNutritionScreen(
          userId: widget.userId,
          initialMeals: _todayLog?.meals ?? [],
        ),
      ),
    );
    fetchNutritionData(); // Refresh UI upon returning
  }

  // Widget: Renders the list of past logged days
  Widget _buildHistoryList() {
    if (_savedLogs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No meals logged yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true, // Prevents layout errors inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Scroll handled by parent
      itemCount: _savedLogs.length,
      itemBuilder: (context, index) {
        final log = _savedLogs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            title: Text(
              // Simple manual date formatting
              "${log.date.day.toString().padLeft(2, '0')} / ${log.date.month.toString().padLeft(2, '0')} / ${log.date.year}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "${log.totalCalories} kcal",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        );
      },
    );
  }
}

//  SCREEN 2: DAILY MEAL LIST LOG
class LogNutritionScreen extends StatefulWidget {
  final int userId;
  final List<MealItem> initialMeals; // Added to receive today's existing meals

  const LogNutritionScreen({
    super.key,
    required this.userId,
    this.initialMeals = const [],
  });

  @override
  State<LogNutritionScreen> createState() => _LogNutritionScreenState();
}

class _LogNutritionScreenState extends State<LogNutritionScreen> {
  late List<MealItem> _meals;

  @override
  void initState() {
    super.initState();
    // Initialize with the meals passed from the main screen
    _meals = List.from(widget.initialMeals);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "Log Meals",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // List of meals currently added
          Expanded(
            child: _meals.isEmpty
                ? const Center(
                    child: Text(
                      "No meals today.\nClick 'Add Meal' to start tracking!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _meals.length,
                    itemBuilder: (context, i) => Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          _meals[i].name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${_meals[i].proteins}g P | ${_meals[i].carbs}g C | ${_meals[i].fats}g F",
                        ),
                        trailing: Text(
                          "${_meals[i].calories} kcal",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // Bottom Actions Panel (Add Meal & Done Buttons)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Button 1: Add Another Meal
                OutlinedButton.icon(
                  onPressed: () async {
                    // Navigate to the form and wait for a MealItem result
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddMealScreen(),
                      ),
                    );

                    if (result != null && result is MealItem) {
                      // POST TO BACKEND IMMEDIATELY!
                      try {
                        await http.post(
                          Uri.parse('$baseUrl/api/nutrition'),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "user_id": widget.userId,
                            "meal_name": result.name,
                            "calories": result.calories,
                            "proteins": result.proteins,
                            "carbs": result.carbs,
                            "fats": result.fats,
                            "date": DateTime.now().toIso8601String(),
                          }),
                        );

                        // Update local list to show the new meal immediately
                        setState(() => _meals.add(result));
                      } catch (e) {
                        print("Error saving meal: $e");
                      }
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    "Add New Meal",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Button 2: Done & Return
                ElevatedButton(
                  onPressed: () {
                    // Pop the screen. This triggers fetchNutritionData() in the parent screen!
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Done & Return",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//  SCREEN 3: ADD MEAL FORM
class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});
  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  // Text controllers to capture user input
  final _name = TextEditingController();
  final _cal = TextEditingController();
  final _prot = TextEditingController();
  final _carb = TextEditingController();
  final _fat = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Meal Details"),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: "Meal Name (e.g. Lunch)",
              ),
            ),
            TextField(
              controller: _cal,
              decoration: const InputDecoration(labelText: "Calories"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            // Macronutrients row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _prot,
                    decoration: const InputDecoration(labelText: "Protein (g)"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _carb,
                    decoration: const InputDecoration(labelText: "Carbs (g)"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _fat,
                    decoration: const InputDecoration(labelText: "Fat (g)"),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Save Button
            ElevatedButton(
              onPressed: () {
                String safeName = _name.text.isEmpty ? "Snack" : _name.text;
                Navigator.pop(
                  context,
                  MealItem(
                    name: safeName,
                    calories: int.tryParse(_cal.text) ?? 0,
                    proteins: int.tryParse(_prot.text) ?? 0,
                    carbs: int.tryParse(_carb.text) ?? 0,
                    fats: int.tryParse(_fat.text) ?? 0,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Save Meal",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
