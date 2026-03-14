import 'package:mysql1/mysql1.dart';
import '../models/hydration_log.dart';

// DAO responsible for handling HydrationLog operations.
class HydrationDao {
  final MySqlConnection _conn;

  HydrationDao(this._conn);

  // Logs new water intake.
  Future<void> addHydration(HydrationLog log) async {
    await _conn.query('INSERT INTO HydrationLog (user_id, ml) VALUES (?, ?)', [
      log.userId,
      log.waterMl,
    ]);
  }

  // Retrieves user hydration history.
  Future<List<HydrationLog>> getHydrationByUser(int userId) async {
    var results = await _conn.query(
      'SELECT * FROM HydrationLog WHERE user_id = ? ORDER BY date_logged DESC',
      [userId],
    );
    return results.map((row) => HydrationLog.fromRow(row.fields)).toList();
  }

  // Updates a hydration record amount.
  Future<void> updateHydration(HydrationLog log) async {
    await _conn.query('UPDATE HydrationLog SET ml = ? WHERE id = ?', [
      log.waterMl,
      log.id,
    ]);
  }
}
