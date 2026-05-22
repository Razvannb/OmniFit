import 'package:omnifit_backend/db/database.dart';
import 'package:omnifit_backend/models/workout.dart';

class WorkoutRepository {
  Future<int> saveWorkout(Workout workout, {dynamic incomingId}) async {
    final conn = await Database.connect();
    int currentWorkoutId;

    if (incomingId != null && !incomingId.toString().contains('#')) {
      currentWorkoutId = int.parse(incomingId.toString());
      await conn.query(
        'UPDATE Workouts SET name = ?, rpe = ?, date_created = ? WHERE id = ?',
        [workout.workoutName, workout.rpe, workout.date.toUtc(), currentWorkoutId],
      );
      await conn.query('DELETE FROM Sets WHERE workoutID = ?', [currentWorkoutId]);
    } else {
      var result = await conn.query(
        'INSERT INTO Workouts (user_id, name, rpe, date_created) VALUES (?, ?, ?, ?)',
        [workout.userId, workout.workoutName, workout.rpe, workout.date.toUtc()],
      );
      currentWorkoutId = result.insertId!;
    }

    for (var ex in workout.exercises) {
      await conn.query(
        'INSERT INTO Sets (workoutID, exerciseName, muscleGroup, setsCount, reps, recoveryBetweenSets, recoveryExercise) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          currentWorkoutId,
          ex.exerciseName,
          ex.muscleGroup,
          ex.setsCount,
          ex.reps,
          ex.recoveryBetweenSets,
          ex.recoveryExercise,
        ],
      );
    }

    return currentWorkoutId;
  }

  Future<List<Workout>> getWorkoutsByUserId(int userId) async {
    final conn = await Database.connect();
    List<Workout> workoutsList = [];

    var workouts = await conn.query(
      'SELECT * FROM Workouts WHERE user_id = ? ORDER BY date_created DESC',
      [userId],
    );

    for (var w in workouts) {
      int workoutId = w['id'];
      var sets = await conn.query('SELECT * FROM Sets WHERE workoutID = ?', [workoutId]);

      List<WorkoutSet> exercises = [];
      for (var s in sets) {
        exercises.add(WorkoutSet(
          id: s['id'],
          workoutId: s['workoutID'],
          exerciseName: s['exerciseName'] ?? '',
          muscleGroup: s['muscleGroup'] ?? '',
          setsCount: s['setsCount'] ?? 0,
          reps: (s['reps'] ?? '').toString(),
          recoveryBetweenSets: s['recoveryBetweenSets'] ?? 60,
          recoveryExercise: s['recoveryExercise'] ?? 0,
        ));
      }

      workoutsList.add(Workout(
        id: workoutId,
        userId: userId,
        workoutName: w['name'],
        date: w['date_created'] as DateTime,
        rpe: double.parse(w['rpe'].toString()),
        exercises: exercises,
      ));
    }

    return workoutsList;
  }

  Future<void> deleteWorkout(int workoutId) async {
    final conn = await Database.connect();
    await conn.query('DELETE FROM Workouts WHERE id = ?', [workoutId]);
  }
}
