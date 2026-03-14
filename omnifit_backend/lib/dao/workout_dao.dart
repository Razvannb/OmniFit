import 'package:mysql1/mysql1.dart';
import '../models/workout.dart';

// DAO (Data Access Object) responsible for handling Workout database operations.
class WorkoutDao {
  final MySqlConnection _conn;

  // Constructor that requires a valid MySQL connection.
  WorkoutDao(this._conn);

  // Creates a new workout session for a user and returns its generated ID.
  Future<int> createWorkout(int userId) async {
    var result = await _conn.query(
      // Executes an INSERT query safely using a parameterized input to prevent SQL injection.
      'INSERT INTO Workouts (user_id) VALUES (?)',
      [userId],
    );

    // Returns the newly auto-generated ID of the workout, useful for linking subsequent sets.
    return result.insertId!;
  }

  // Retrieves a list of all workouts for a specific user, sorted from newest to oldest.
  Future<List<Workout>> getWorkoutsByUser(int userId) async {
    var results = await _conn.query(
      // Executes a SELECT query filtering by user_id and sorting by creation date.
      'SELECT * FROM Workouts WHERE user_id = ? ORDER BY date_created DESC',
      [userId],
    );

    // Converts the raw MySQL rows into a list of Workout Dart objects.
    return results.map((row) => Workout.fromRow(row.fields)).toList();
  }
}
