import 'package:mysql1/mysql1.dart';
import '../models/rpe_log.dart';

// DAO (Data Access Object) responsible for handling RPE (Rate of Perceived Exertion) database operations.
class RpeLogDao {
  final MySqlConnection _conn;

  // Constructor that requires a valid MySQL connection.
  RpeLogDao(this._conn);

  // Adds a new RPE score for a completed workout to the database.
  Future<void> addRpeLog(RpeLog log) async {
    await _conn.query(
      // Executes an INSERT query safely using parameterized inputs (?, ?) to prevent SQL injection.
      'INSERT INTO RPE_Log (workout_id, rpe_value) VALUES (?, ?)',
      [log.workoutId, log.rpeValue],
    );
  }

  // Retrieves the RPE score for a specific workout (useful for displaying past effort levels).
  Future<RpeLog?> getRpeByWorkout(int workoutId) async {
    var results = await _conn.query(
      // Executes a SELECT query filtering by workout_id.
      'SELECT * FROM RPE_Log WHERE workout_id = ?',
      [workoutId],
    );

    // Updates a previously logged RPE (Rate of Perceived Exertion) score.
    Future<void> updateRpeLog(RpeLog log) async {
      await _conn.query(
        // Executes an UPDATE query to modify the rpe_value for a record identified by its unique ID.
        'UPDATE RPE_Log SET rpe_value = ? WHERE id = ?',
        [log.rpeValue, log.id],
      );
    }

    // If no RPE score was logged for this workout, return null.
    if (results.isEmpty) return null;

    // Converts the first (and only) matching MySQL row into an RpeLog Dart object.
    return RpeLog.fromRow(results.first.fields);
  }
}
