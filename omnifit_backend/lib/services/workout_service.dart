import 'package:omnifit_backend/models/workout.dart';
import 'package:omnifit_backend/repositories/workout_repository.dart';

class WorkoutService {
  final WorkoutRepository _workoutRepository = WorkoutRepository();

  Future<int> saveWorkout(Workout workout, {dynamic incomingId}) async {
    return await _workoutRepository.saveWorkout(workout, incomingId: incomingId);
  }

  Future<List<Workout>> getWorkouts(String userId) async {
    final parsedUserId = int.tryParse(userId) ?? 1;
    return await _workoutRepository.getWorkoutsByUserId(parsedUserId);
  }

  Future<void> deleteWorkout(int workoutId) async {
    await _workoutRepository.deleteWorkout(workoutId);
  }
}
