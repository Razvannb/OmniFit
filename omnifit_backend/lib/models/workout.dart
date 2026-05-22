class WorkoutSet {
  final int? id;
  final int? workoutId;
  final String exerciseName;
  final String muscleGroup;
  final int setsCount;
  final String reps;
  final int recoveryBetweenSets;
  final int recoveryExercise;

  WorkoutSet({
    this.id,
    this.workoutId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.setsCount,
    required this.reps,
    required this.recoveryBetweenSets,
    required this.recoveryExercise,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'],
      workoutId: json['workoutID'],
      exerciseName: json['exerciseName'] ?? '',
      muscleGroup: json['muscleGroup'] ?? '',
      setsCount: json['sets'] ?? json['setsCount'] ?? 0,
      reps: (json['reps'] ?? '').toString(),
      recoveryBetweenSets: json['recoveryBetweenSets'] ?? 60,
      recoveryExercise: json['recoveryExercise'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'sets': setsCount,
      'reps': reps,
      'recoveryBetweenSets': recoveryBetweenSets,
      'recoveryExercise': recoveryExercise,
    };
  }
}

class Workout {
  final int? id;
  final int userId;
  final String workoutName;
  final DateTime date;
  final double rpe;
  final List<WorkoutSet> exercises;

  Workout({
    this.id,
    required this.userId,
    required this.workoutName,
    required this.date,
    required this.rpe,
    required this.exercises,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    var list = json['exercises'] as List? ?? [];
    List<WorkoutSet> exercisesList = list.map((e) => WorkoutSet.fromJson(e)).toList();

    return Workout(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: json['user_id'] ?? 1,
      workoutName: json['workoutName'] ?? 'Unnamed Workout',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      rpe: (json['rpe'] ?? 5.0) as double,
      exercises: exercisesList,
    );
  }

  Map<String, dynamic> toJson() {
    int workoutGlobalRest = 60;
    if (exercises.isNotEmpty) {
      workoutGlobalRest = exercises.first.recoveryBetweenSets;
    }

    return {
      'id': id,
      'workoutName': workoutName,
      'date': date.toIso8601String(),
      'rpe': rpe,
      'globalRestTime': workoutGlobalRest,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}
