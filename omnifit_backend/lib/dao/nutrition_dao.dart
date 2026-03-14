import 'package:mysql1/mysql1.dart';
import '../models/nutrition_log.dart';

// DAO (Data Access Object) responsible for handling NutritionLog database operations.
class NutritionDao {
  final MySqlConnection _conn;

  // Constructor that requires a valid MySQL connection.
  NutritionDao(this._conn);

  // Adds a new nutrition log (consumed calories) to the database.
  Future<void> addNutrition(NutritionLog log) async {
    await _conn.query(
      // Executes an INSERT query safely using parameterized inputs (?, ?) to prevent SQL injection.
      'INSERT INTO NutritionLog (user_id, calories) VALUES (?, ?)',
      [log.userId, log.calories],
    );
  }

  // Retrieves a list of all nutrition logs for a specific user, sorted from newest to oldest.
  Future<List<NutritionLog>> getNutritionByUser(int userId) async {
    var results = await _conn.query(
      // Executes a SELECT query filtering by user_id and sorting by date.
      'SELECT * FROM NutritionLog WHERE user_id = ? ORDER BY date_logged DESC',
      [userId],
    );

    // Converts the raw MySQL rows into a list of NutritionLog Dart objects.
    return results.map((row) => NutritionLog.fromRow(row.fields)).toList();
  }
}
