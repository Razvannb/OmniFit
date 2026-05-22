import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:omnifit_backend/models/hydration.dart';
import 'package:omnifit_backend/services/hydration_service.dart';

class HydrationController {
  final HydrationService _hydrationService = HydrationService();

  Future<Response> saveHydration(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);

      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;

      // Instantiate HydrationLog entity with secure verified userId
      final log = HydrationLog(
        userId: userId,
        amount: data['amount'] ?? 0,
        date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      );

      await _hydrationService.saveHydration(log);

      return Response.ok(
        json.encode({'status': 'success'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error saving hydration: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getHydration(Request req) async {
    try {
      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final logs = await _hydrationService.getHydration(userId.toString());

      final jsonList = logs.map((l) => l.toJson()).toList();

      return Response.ok(
        json.encode(jsonList),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error getting hydration: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> saveHydrationGoal(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);

      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final goal = data['daily_water_goal'] ?? 2500;

      await _hydrationService.saveHydrationGoal(userId, goal);

      return Response.ok(
        json.encode({'status': 'success'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error saving hydration goal: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getHydrationGoal(Request req) async {
    try {
      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final goal = await _hydrationService.getHydrationGoal(userId.toString());

      return Response.ok(
        json.encode({'daily_water_goal': goal}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error getting hydration goal: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
