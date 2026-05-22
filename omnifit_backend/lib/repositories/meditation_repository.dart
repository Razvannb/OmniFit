import 'package:omnifit_backend/db/database.dart';
import 'package:omnifit_backend/models/meditation.dart';

class MeditationRepository {
  Future<void> saveMeditation(MeditationLog log) async {
    final conn = await Database.connect();
    await conn.query(
      'INSERT INTO MeditationLog (user_id, minutes, date_logged) VALUES (?, ?, ?)',
      [log.userId, log.minutes, log.date.toUtc()],
    );
  }

  Future<List<MeditationLog>> getMeditationByUserId(int userId) async {
    final conn = await Database.connect();
    var logs = await conn.query(
      'SELECT minutes, date_logged FROM MeditationLog WHERE user_id = ? ORDER BY date_logged DESC',
      [userId],
    );

    List<MeditationLog> results = [];
    for (var row in logs) {
      results.add(MeditationLog(
        userId: userId,
        minutes: row['minutes'] ?? 0,
        date: row['date_logged'] as DateTime,
      ));
    }

    return results;
  }

  Future<void> saveMeditationGoal(int userId, int minutesGoal) async {
    final conn = await Database.connect();
    var existing = await conn.query('SELECT id FROM MeditationGoals WHERE user_id = ?', [userId]);

    if (existing.isNotEmpty) {
      await conn.query('UPDATE MeditationGoals SET daily_minutes_goal = ? WHERE user_id = ?', [minutesGoal, userId]);
    } else {
      await conn.query('INSERT INTO MeditationGoals (user_id, daily_minutes_goal) VALUES (?, ?)', [userId, minutesGoal]);
    }
  }

  Future<int> getMeditationGoal(int userId) async {
    final conn = await Database.connect();
    var result = await conn.query('SELECT daily_minutes_goal FROM MeditationGoals WHERE user_id = ?', [userId]);

    int goal = 30; // Default
    if (result.isNotEmpty) {
      goal = int.parse(result.first['daily_minutes_goal'].toString());
    }

    return goal;
  }
}
