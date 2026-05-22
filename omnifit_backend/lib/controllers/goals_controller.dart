import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:omnifit_backend/models/goal.dart';
import 'package:omnifit_backend/services/goals_service.dart';

class GoalsController {
  final GoalsService _goalsService = GoalsService();

  Future<Response> saveGoal(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);

      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;

      // Instantiate Goal entity with secure verified userId
      final goal = Goal(
        userId: userId,
        muscleGroup: data['muscleGroup'] ?? '',
        targetSets: data['targetSets'] ?? 0,
      );

      await _goalsService.saveGoal(goal);

      return Response.ok(
        json.encode({'status': 'success'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error saving Goal: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getGoals(Request req) async {
    try {
      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final goals = await _goalsService.getGoals(userId);

      final jsonList = goals.map((g) => g.toJson()).toList();

      return Response.ok(
        json.encode(jsonList),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error getting Goals: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
