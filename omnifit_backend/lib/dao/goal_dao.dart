import 'package:mysql1/mysql1.dart';
import '../models/goal.dart';

// DAO (Data Access Object) responsible for handling Goal database operations.
class GoalDao {
  final MySqlConnection _conn;

  // Constructor that requires a valid MySQL connection.
  GoalDao(this._conn);

  // Adds a new user fitness goal to the database.
  Future<void> addGoal(Goal goal) async {
    await _conn.query(
      // Executes an INSERT query safely using parameterized inputs (?, ?, ?) to prevent SQL injection.
      'INSERT INTO Goals (user_id, muscle_group, target_sets) VALUES (?, ?, ?)',
      [goal.userId, goal.muscleGroup, goal.targetSets],
    );
  }

  // Retrieves a list of all goals set by a specific user.
  Future<List<Goal>> getGoalsByUser(int userId) async {
    var results = await _conn.query(
      // Executes a SELECT query filtering by user_id.
      'SELECT * FROM Goals WHERE user_id = ?',
      [userId],
    );

    // Converts the raw MySQL rows into a list of Goal Dart objects.
    return results.map((row) => Goal.fromRow(row.fields)).toList();
  }
}
