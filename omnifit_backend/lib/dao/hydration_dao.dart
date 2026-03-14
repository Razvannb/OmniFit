import 'package:mysql1/mysql1.dart';
import '../models/hydration_log.dart';

// DAO (Data Access Object) responsible for handling HydrationLog database operations.
class HydrationDao {
  final MySqlConnection _conn;

  // Constructor that requires a valid MySQL connection.
  HydrationDao(this._conn);

  // Adds a new hydration record (water intake) to the database.
  Future<void> addHydration(HydrationLog log) async {
    await _conn.query(
      // Executes an INSERT query safely using parameterized inputs (?, ?) to prevent SQL injection.
      'INSERT INTO HydrationLog (user_id, water_ml) VALUES (?, ?)',
      [log.userId, log.waterMl],
    );
  }

  // Retrieves a list of all hydration logs for a specific user, sorted from newest to oldest.
  Future<List<HydrationLog>> getHydrationByUser(int userId) async {
    var results = await _conn.query(
      // Executes a SELECT query filtering by user_id and sorting by date.
      'SELECT * FROM HydrationLog WHERE user_id = ? ORDER BY date_logged DESC',
      [userId],
    );

    // Converts the raw MySQL rows into a list of HydrationLog Dart objects.
    return results.map((row) => HydrationLog.fromRow(row.fields)).toList();
  }
}
