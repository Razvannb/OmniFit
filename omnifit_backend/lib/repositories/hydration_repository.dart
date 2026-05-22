import 'package:omnifit_backend/db/database.dart';
import 'package:omnifit_backend/models/hydration.dart';

class HydrationRepository {
  Future<void> saveHydration(HydrationLog log) async {
    final conn = await Database.connect();
    await conn.query(
      'INSERT INTO HydrationLog (user_id, amount, date_logged) VALUES (?, ?, ?)',
      [log.userId, log.amount, log.date.toUtc()],
    );
  }

  Future<List<HydrationLog>> getHydrationByUserId(int userId) async {
    final conn = await Database.connect();
    var logs = await conn.query(
      'SELECT amount, date_logged FROM HydrationLog WHERE user_id = ? ORDER BY date_logged DESC',
      [userId],
    );

    List<HydrationLog> results = [];
    for (var row in logs) {
      results.add(HydrationLog(
        userId: userId,
        amount: row['amount'] ?? 0,
        date: row['date_logged'] as DateTime,
      ));
    }

    return results;
  }

  Future<void> saveHydrationGoal(int userId, int waterGoal) async {
    final conn = await Database.connect();
    var existing = await conn.query('SELECT id FROM HydrationGoals WHERE user_id = ?', [userId]);

    if (existing.isNotEmpty) {
      await conn.query('UPDATE HydrationGoals SET daily_water_goal = ? WHERE user_id = ?', [waterGoal, userId]);
    } else {
      await conn.query('INSERT INTO HydrationGoals (user_id, daily_water_goal) VALUES (?, ?)', [userId, waterGoal]);
    }
  }

  Future<int> getHydrationGoal(int userId) async {
    final conn = await Database.connect();
    var result = await conn.query('SELECT daily_water_goal FROM HydrationGoals WHERE user_id = ?', [userId]);

    int goal = 2500; // Default
    if (result.isNotEmpty) {
      goal = int.parse(result.first['daily_water_goal'].toString());
    }

    return goal;
  }
}
