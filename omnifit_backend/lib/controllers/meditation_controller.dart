import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:omnifit_backend/models/meditation.dart';
import 'package:omnifit_backend/services/meditation_service.dart';

class MeditationController {
  final MeditationService _meditationService = MeditationService();

  Future<Response> saveMeditation(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);

      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;

      // Instantiate MeditationLog entity with secure verified userId
      final log = MeditationLog(
        userId: userId,
        minutes: data['minutes'] ?? 0,
        date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      );

      await _meditationService.saveMeditation(log);

      return Response.ok(
        json.encode({'status': 'success'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error saving meditation: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getMeditation(Request req) async {
    try {
      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final logs = await _meditationService.getMeditation(userId.toString());

      final jsonList = logs.map((l) => l.toJson()).toList();

      return Response.ok(
        json.encode(jsonList),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error getting meditation: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> saveMeditationGoal(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);

      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final goal = data['daily_minutes_goal'] ?? 30;

      await _meditationService.saveMeditationGoal(userId, goal);

      return Response.ok(
        json.encode({'status': 'success'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error saving meditation goal: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getMeditationGoal(Request req) async {
    try {
      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final goal = await _meditationService.getMeditationGoal(userId.toString());

      return Response.ok(
        json.encode({'daily_minutes_goal': goal}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error getting meditation goal: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
