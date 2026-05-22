import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:omnifit_backend/models/nutrition.dart';
import 'package:omnifit_backend/services/nutrition_service.dart';

class NutritionController {
  final NutritionService _nutritionService = NutritionService();

  Future<Response> saveNutrition(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);

      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;

      // Instantiate NutritionLog entity with secure verified userId
      final log = NutritionLog(
        userId: userId,
        mealName: data['meal_name'] ?? 'Meal',
        calories: data['calories'] ?? 0,
        proteins: data['proteins'] ?? 0,
        carbs: data['carbs'] ?? 0,
        fats: data['fats'] ?? 0,
        date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      );

      await _nutritionService.saveNutrition(log);

      return Response.ok(
        json.encode({'status': 'success'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error saving nutrition: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getNutrition(Request req) async {
    try {
      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final logs = await _nutritionService.getNutrition(userId.toString());

      final jsonList = logs.map((l) => l.toJson()).toList();

      return Response.ok(
        json.encode(jsonList),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error getting nutrition: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> saveNutritionGoal(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);

      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final goal = data['daily_calorie_goal'] ?? 2400;

      await _nutritionService.saveNutritionGoal(userId, goal);

      return Response.ok(
        json.encode({'status': 'success'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error saving nutrition goal: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getNutritionGoal(Request req) async {
    try {
      // Securely extract verified userId from decoded token context!
      final userId = req.context['userId'] as int;
      final goal = await _nutritionService.getNutritionGoal(userId.toString());

      return Response.ok(
        json.encode({'daily_calorie_goal': goal}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Error getting nutrition goal: $e");
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
