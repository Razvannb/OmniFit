import 'package:mysql1/mysql1.dart';
import '../models/goal.dart';

// DAO responsible for handling Goal database operations (INSERT, SELECT, UPDATE).
class GoalDao {
  final MySqlConnection _conn;

  GoalDao(this._conn);

  // Adds a new user fitness goal to the database.
  Future<void> addGoal(Goal goal) async {
    await _conn.query(
      'INSERT INTO Goals (user_id, muscle_group, target_sets) VALUES (?, ?, ?)',
      [goal.userId, goal.muscleGroup, goal.targetSets],
    );
  }

  // Retrieves all goals set by a specific user.
  Future<List<Goal>> getGoalsByUser(int userId) async {
    var results = await _conn.query('SELECT * FROM Goals WHERE user_id = ?', [
      userId,
    ]);
    return results.map((row) => Goal.fromRow(row.fields)).toList();
  }

  // Updates an existing goal's details (muscle group or target sets).
  Future<void> updateGoal(Goal goal) async {
    await _conn.query(
      'UPDATE Goals SET muscle_group = ?, target_sets = ? WHERE id = ?',
      [goal.muscleGroup, goal.targetSets, goal.id],
    );
  }
}
