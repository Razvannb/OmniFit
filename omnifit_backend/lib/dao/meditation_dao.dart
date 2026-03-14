import 'package:mysql1/mysql1.dart';
import '../models/meditation_log.dart';

// DAO (Data Access Object) responsible for handling MeditationLog database operations.
class MeditationDao {
  final MySqlConnection _conn;

  // Constructor that requires a valid MySQL connection.
  MeditationDao(this._conn);

  // Adds a new meditation session to the database.
  Future<void> addMeditation(MeditationLog log) async {
    await _conn.query(
      // Executes an INSERT query safely using parameterized inputs (?, ?) to prevent SQL injection.
      'INSERT INTO MeditationLog (user_id, duration_minutes) VALUES (?, ?)',
      [log.userId, log.durationMinutes],
    );
  }

  // obtains a list of all meditation sessions for a specific user, sorted from newest to oldest.
  Future<List<MeditationLog>> getMeditationByUser(int userId) async {
    var results = await _conn.query(
      // Executes a SELECT query filtering by user_id.
      'SELECT * FROM MeditationLog WHERE user_id = ? ORDER BY date_logged DESC',
      [userId],
    );

    // Converts the raw MySQL rows into a list of MeditationLog Dart objects.
    return results.map((row) => MeditationLog.fromRow(row.fields)).toList();
  }
}
