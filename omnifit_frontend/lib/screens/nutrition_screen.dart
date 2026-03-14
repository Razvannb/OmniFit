import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- DATA MODELS ---
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
  }) : id = UniqueKey().toString();
}

class NutritionDayItem {
  final String id;
  DateTime date;
  List<MealItem> meals;

  NutritionDayItem({required this.date, required this.meals})
    : id = UniqueKey().toString();

  int get totalCalories => meals.fold(0, (sum, meal) => sum + meal.calories);
  int get totalProteins => meals.fold(0, (sum, meal) => sum + meal.proteins);
  int get totalCarbs => meals.fold(0, (sum, meal) => sum + meal.carbs);
  int get totalFats => meals.fold(0, (sum, meal) => sum + meal.fats);
}

// --- SCREEN 1: NUTRITION LOG ---
class NutritionScreen extends StatefulWidget {
  final int userId;
  const NutritionScreen({super.key, required this.userId});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final List<NutritionDayItem> _savedLogs = [];
  int _dailyCalorieGoal = 2400;

  @override
  void initState() {
    super.initState();
    fetchNutritionData();
  }

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
      return null;
    }
  }

  int get _caloriesConsumedToday => _todayLog?.totalCalories ?? 0;
  int get _caloriesRemaining => _dailyCalorieGoal - _caloriesConsumedToday;
  double get _progressPercentage => _dailyCalorieGoal == 0
      ? 0.0
      : (_caloriesConsumedToday / _dailyCalorieGoal).clamp(0.0, 1.0);

  Future<void> fetchNutritionData() async {
    setState(() {
      if (_savedLogs.isEmpty) {
        _savedLogs.add(
          NutritionDayItem(
            date: DateTime.now(),
            meals: [
              MealItem(
                name: 'Lunch',
                calories: 850,
                proteins: 50,
                carbs: 80,
                fats: 20,
              ),
              MealItem(
                name: 'Dinner',
                calories: 800,
                proteins: 40,
                carbs: 40,
                fats: 15,
              ),
            ],
          ),
        );
      }
    });
  }

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
            onPressed: () {
              setState(
                () => _dailyCalorieGoal = int.tryParse(controller.text) ?? 2400,
              );
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isExceeded = _caloriesRemaining < 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Nutrition Log',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Calories',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
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
            const SizedBox(height: 20),

            _buildCalorieProgressCard(isExceeded),
            const SizedBox(height: 25),

            _buildMacronutrientsCard(),
            const SizedBox(height: 35),

            const Text(
              "History",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildHistoryList(),

            // --- AICI ESTE NOUL GHENAR CU SFATUL ---
            _buildTipBox(),

            const SizedBox(
              height: 80,
            ), // Spațiu extra pentru a nu fi acoperit de buton
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToLogNutrition(),
        backgroundColor: Colors.black,
        label: const Text(
          'Log New Day',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Widget pentru caseta cu sfat
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isExceeded ? Colors.redAccent : Colors.blueAccent,
                  ),
                ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniStat(
                isExceeded ? 'Exceeded' : 'Remaining',
                '${_caloriesRemaining.abs()}',
                isExceeded ? Colors.redAccent : Colors.blueAccent,
              ),
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
                const Color(0xFFFFE5E5),
                Colors.red.shade700,
              ),
              _buildMacroCircle(
                'Carbs',
                '${log?.totalCarbs ?? 0}g',
                const Color(0xFFE5F0FF),
                Colors.blue.shade700,
              ),
              _buildMacroCircle(
                'Fats',
                '${log?.totalFats ?? 0}g',
                const Color(0xFFFFF9E5),
                Colors.orange.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  void _navigateToLogNutrition() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogNutritionScreen(userId: widget.userId),
      ),
    );
    setState(() {}); // Refresh UI
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
              "${log.date.day}.${log.date.month}.${log.date.year}",
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

// --- ECRANELE DE ADAUGARE (LogNutritionScreen & AddMealScreen) ---
// (Am lăsat restul codului așa cum era în cererea ta pentru a asigura funcționarea listelor)
class LogNutritionScreen extends StatefulWidget {
  final int userId;
  const LogNutritionScreen({super.key, required this.userId});
  @override
  State<LogNutritionScreen> createState() => _LogNutritionScreenState();
}

class _LogNutritionScreenState extends State<LogNutritionScreen> {
  List<MealItem> _meals = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Meals")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(_meals[i].name),
                subtitle: Text(
                  "${_meals[i].proteins}g P | ${_meals[i].carbs}g C | ${_meals[i].fats}g F",
                ),
                trailing: Text("${_meals[i].calories} kcal"),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddMealScreen(),
                  ),
                );
                if (result != null) setState(() => _meals.add(result));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Add Meal",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});
  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _name = TextEditingController();
  final _cal = TextEditingController();
  final _prot = TextEditingController();
  final _carb = TextEditingController();
  final _fat = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meal Details")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: "Meal Name"),
            ),
            TextField(
              controller: _cal,
              decoration: const InputDecoration(labelText: "Calories"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
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
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                MealItem(
                  name: _name.text,
                  calories: int.tryParse(_cal.text) ?? 0,
                  proteins: int.tryParse(_prot.text) ?? 0,
                  carbs: int.tryParse(_carb.text) ?? 0,
                  fats: int.tryParse(_fat.text) ?? 0,
                ),
              ),
              child: const Text("Save Meal"),
            ),
          ],
        ),
      ),
    );
  }
}
