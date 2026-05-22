import 'package:omnifit_backend/repositories/workout_repository.dart';
import 'package:omnifit_backend/repositories/goals_repository.dart';

class DashboardService {
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  final GoalsRepository _goalsRepository = GoalsRepository();

  Future<String> getDashboardRecommendation(int userId) async {
    // 1. Calculate the Average RPE (Intensity) from the last 3 workouts
    final workouts = await _workoutRepository.getWorkoutsByUserId(userId);
    final last3 = workouts.take(3).toList();

    double avgRpe = 5.0;
    if (last3.isNotEmpty) {
      double sum = last3.fold(0.0, (prev, w) => prev + w.rpe);
      avgRpe = sum / last3.length;
    }

    // 2. Find a "Lagging Muscle" (a muscle group where the weekly goal hasn't been met)
    final goals = await _goalsRepository.getGoalsByUserId(userId);
    String laggingMuscle = "";

    for (var g in goals) {
      if (g.currentSets < g.targetSets) {
        laggingMuscle = g.muscleGroup;
        break;
      }
    }

    // 3. Generate the actual string recommendation based on the collected data
    String recommendation = "";
    if (avgRpe >= 8.0) {
      // They are training too hard -> Suggest recovery
      recommendation =
          "Attention! You have had very intense workouts recently (average RPE: ${avgRpe.toStringAsFixed(1)}/10). We recommend a day of active recovery, stretching, or yoga today!";
    } else if (laggingMuscle.isNotEmpty) {
      // They are missing goals -> Suggest working out the lagging muscle
      recommendation =
          "You feel good (RPE: ${avgRpe.toStringAsFixed(1)}/10). Today would be ideal for doing a workout for '$laggingMuscle' to reach your weekly set goal!";
    } else {
      // Everything is perfect
      recommendation =
          "You are a champion! The RPE is optimal and you have already reached all your weekly set goals. You can do any workout you want today!";
    }

    return recommendation;
  }
}
