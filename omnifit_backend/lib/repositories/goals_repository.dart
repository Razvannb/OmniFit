import 'package:omnifit_backend/db/database.dart';
import 'package:omnifit_backend/models/goal.dart';

class GoalsRepository {
  Future<void> saveGoal(Goal goal) async {
    final conn = await Database.connect();

    var existing = await conn.query(
      'SELECT id FROM Goals WHERE user_id = ? AND muscle_group = ?',
      [goal.userId, goal.muscleGroup],
    );

    if (existing.isNotEmpty) {
      await conn.query('UPDATE Goals SET target_sets = ? WHERE id = ?', [
        goal.targetSets,
        existing.first['id'],
      ]);
    } else {
      await conn.query(
        'INSERT INTO Goals (user_id, muscle_group, target_sets) VALUES (?, ?, ?)',
        [goal.userId, goal.muscleGroup, goal.targetSets],
      );
    }
  }

  Future<List<Goal>> getGoalsByUserId(int userId) async {
    final conn = await Database.connect();
    var goals = await conn.query('SELECT * FROM Goals WHERE user_id = ?', [userId]);
    List<Goal> finalGoals = [];

    for (var g in goals) {
      String muscle = g['muscle_group'].toString();
      int target = int.tryParse(g['target_sets'].toString()) ?? 0;

      var progressQuery = await conn.query(
        '''
        SELECT SUM(s.setsCount) as total 
        FROM Sets s 
        JOIN Workouts w ON s.workoutID = w.id 
        WHERE w.user_id = ? AND s.muscleGroup = ? AND w.date_created >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
      ''',
        [userId, muscle],
      );

      int currentSets = 0;
      if (progressQuery.isNotEmpty && progressQuery.first['total'] != null) {
        currentSets = double.parse(progressQuery.first['total'].toString()).toInt();
      }

      finalGoals.add(Goal(
        id: g['id'],
        userId: userId,
        muscleGroup: muscle,
        targetSets: target,
        currentSets: currentSets,
      ));
    }

    return finalGoals;
  }
}
