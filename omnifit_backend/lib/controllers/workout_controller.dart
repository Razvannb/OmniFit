import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:omnifit_backend/models/workout.dart';
import 'package:omnifit_backend/services/workout_service.dart';

class WorkoutController {
  final WorkoutService _workoutService = WorkoutService();

  Future<Response> saveWorkout(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);

      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;

      // Instantiate Workout model, overriding userId with secure verified userId
      final workout = Workout(
        userId: userId,
        workoutName: data['workoutName'] ?? 'Unnamed Workout',
        date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
        rpe: (data['rpe'] ?? 5.0) as double,
        exercises: (data['exercises'] as List? ?? [])
            .map((e) => WorkoutSet.fromJson(e))
            .toList(),
      );

      final incomingId = data['id'];
      final currentWorkoutId = await _workoutService.saveWorkout(
        workout,
        incomingId: incomingId,
      );

      return Response.ok(
        json.encode({'status': 'success', 'workout_id': currentWorkoutId}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error saving workout: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getWorkouts(Request req) async {
    try {
      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final workouts = await _workoutService.getWorkouts(userId.toString());

      final jsonList = workouts.map((w) => w.toJson()).toList();

      return Response.ok(
        json.encode(jsonList),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error fetching workouts: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> deleteWorkout(Request req) async {
    try {
      final workoutIdStr = req.url.queryParameters['id'];
      if (workoutIdStr == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Missing workout ID.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final workoutId = int.parse(workoutIdStr);
      await _workoutService.deleteWorkout(workoutId);

      return Response.ok(
        json.encode({
          'status': 'deleted',
          'message': 'Workout deleted successfully!',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error deleting workout: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
