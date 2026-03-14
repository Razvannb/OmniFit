// Data model representing a specific exercise set within a workout.
class ExerciseSet {
  int? id; // Unique identifier for the set.
  int workoutId; // The ID of the workout this set belongs to.
  String exerciseName; // The name of the exercise performed.
  int setOrder; // The sequence order of this set.
  int reps; // The number of repetitions.
  double weight; // The weight used.

  // NEW FIELDS from documentation:
  int recoveryBetweenSets; // Rest time between sets (in seconds)[cite: 12, 26].
  int
  recoveryExercise; // Rest time between different exercises (in seconds)[cite: 12, 26].

  // Updated constructor
  ExerciseSet({
    this.id,
    required this.workoutId,
    required this.exerciseName,
    required this.setOrder,
    required this.reps,
    this.weight = 0.0,
    required this.recoveryBetweenSets,
    required this.recoveryExercise,
  });

  // Updated factory to include the new columns
  factory ExerciseSet.fromRow(Map<String, dynamic> row) {
    return ExerciseSet(
      id: row['id'],
      workoutId: row['workoutID'],
      exerciseName: row['exerciseName'],
      setOrder: row['setOrder'],
      reps: row['reps'],
      weight: (row['weight'] as num).toDouble(),
      // Adding the new fields from SQL row
      recoveryBetweenSets: row['recoveryBetweenSets'] ?? 0,
      recoveryExercise: row['recoveryExercise'] ?? 0,
    );
  }
}
