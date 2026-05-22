import 'package:omnifit_backend/db/database.dart';
import 'package:omnifit_backend/models/nutrition.dart';

class NutritionRepository {
  Future<void> saveNutrition(NutritionLog log) async {
    final conn = await Database.connect();
    await conn.query(
      'INSERT INTO NutritionLog (user_id, meal_name, calories, proteins, carbs, fats, date_logged) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [log.userId, log.mealName, log.calories, log.proteins, log.carbs, log.fats, log.date.toUtc()],
    );
  }

  Future<List<NutritionLog>> getNutritionByUserId(int userId) async {
    final conn = await Database.connect();
    var logs = await conn.query(
      'SELECT * FROM NutritionLog WHERE user_id = ? ORDER BY date_logged DESC',
      [userId],
    );

    List<NutritionLog> results = [];
    for (var row in logs) {
      results.add(NutritionLog(
        id: row['id'],
        userId: userId,
        mealName: row['meal_name'] ?? 'Meal',
        calories: row['calories'] ?? 0,
        proteins: row['proteins'] ?? 0,
        carbs: row['carbs'] ?? 0,
        fats: row['fats'] ?? 0,
        date: row['date_logged'] as DateTime,
      ));
    }

    return results;
  }

  Future<void> saveNutritionGoal(int userId, int calorieGoal) async {
    final conn = await Database.connect();
    var existing = await conn.query('SELECT id FROM NutritionGoals WHERE user_id = ?', [userId]);

    if (existing.isNotEmpty) {
      await conn.query('UPDATE NutritionGoals SET daily_calorie_goal = ? WHERE user_id = ?', [calorieGoal, userId]);
    } else {
      await conn.query('INSERT INTO NutritionGoals (user_id, daily_calorie_goal) VALUES (?, ?)', [userId, calorieGoal]);
    }
  }

  Future<int> getNutritionGoal(int userId) async {
    final conn = await Database.connect();
    var result = await conn.query('SELECT daily_calorie_goal FROM NutritionGoals WHERE user_id = ?', [userId]);

    int goal = 2400; // Default fallback goal
    if (result.isNotEmpty) {
      goal = int.parse(result.first['daily_calorie_goal'].toString());
    }

    return goal;
  }
}
