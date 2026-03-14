import 'package:mysql1/mysql1.dart';
import '../models/sets.dart';

// DAO responsible for handling ExerciseSet operations, including recovery data.
class SetDao {
  final MySqlConnection _conn;

  SetDao(this._conn);

  // Adds a new exercise set with mandatory recovery fields.
  Future<void> addSet(ExerciseSet exerciseSet) async {
    await _conn.query(
      'INSERT INTO Sets (workoutID, exerciseName, setOrder, reps, weight, recoveryBetweenSets, recoveryExercise) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        exerciseSet.workoutId,
        exerciseSet.exerciseName,
        exerciseSet.setOrder,
        exerciseSet.reps,
        exerciseSet.weight,
        exerciseSet.recoveryBetweenSets,
        exerciseSet.recoveryExercise,
      ],
    );
  }

  // Retrieves all sets for a specific workout, ordered by sequence.
  Future<List<ExerciseSet>> getSetsByWorkout(int workoutId) async {
    var results = await _conn.query(
      'SELECT * FROM Sets WHERE workoutID = ? ORDER BY setOrder ASC',
      [workoutId],
    );
    return results.map((row) => ExerciseSet.fromRow(row.fields)).toList();
  }

  // Updates an existing set (useful for correcting reps or weight logged).
  Future<void> updateSet(ExerciseSet exerciseSet) async {
    await _conn.query(
      'UPDATE Sets SET exerciseName = ?, reps = ?, weight = ?, recoveryBetweenSets = ?, recoveryExercise = ? WHERE id = ?',
      [
        exerciseSet.exerciseName,
        exerciseSet.reps,
        exerciseSet.weight,
        exerciseSet.recoveryBetweenSets,
        exerciseSet.recoveryExercise,
        exerciseSet.id,
      ],
    );
  }
}
