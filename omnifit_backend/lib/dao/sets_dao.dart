import 'package:mysql1/mysql1.dart';
import '../models/sets.dart';

// DAO (Data Access Object) responsible for handling ExerciseSet database operations.
class SetDao {
  final MySqlConnection _conn;

  // Constructor that requires a valid MySQL connection.
  SetDao(this._conn);

  // Adds a new exercise set to the database.
  Future<void> addSet(ExerciseSet exerciseSet) async {
    await _conn.query(
      // Executes an INSERT query safely using parameterized inputs to prevent SQL injection.
      'INSERT INTO Sets (workoutID, exerciseName, setOrder, reps, weight) VALUES (?, ?, ?, ?, ?)',
      [
        exerciseSet.workoutId,
        exerciseSet.exerciseName,
        exerciseSet.setOrder,
        exerciseSet.reps,
        exerciseSet.weight,
      ],
    );
  }

  // Retrieves a list of all sets for a specific workout, ordered by their sequence (setOrder).
  Future<List<ExerciseSet>> getSetsByWorkout(int workoutId) async {
    var results = await _conn.query(
      // Executes a SELECT query filtering by workoutID and sorting them correctly.
      'SELECT * FROM Sets WHERE workoutID = ? ORDER BY setOrder ASC',
      [workoutId],
    );

    // Converts the raw MySQL rows into a list of ExerciseSet Dart objects.
    return results.map((row) => ExerciseSet.fromRow(row.fields)).toList();
  }
}
