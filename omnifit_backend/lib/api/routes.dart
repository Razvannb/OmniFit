import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:omnifit_backend/controllers/workout_controller.dart';
import 'package:omnifit_backend/controllers/goals_controller.dart';
import 'package:omnifit_backend/controllers/dashboard_controller.dart';
import 'package:omnifit_backend/controllers/nutrition_controller.dart';
import 'package:omnifit_backend/controllers/hydration_controller.dart';
import 'package:omnifit_backend/controllers/meditation_controller.dart';
import 'package:omnifit_backend/controllers/auth_controller.dart';

Router getApiRouter() {
  final router = Router();

  // Instantiate Controllers
  final workoutController = WorkoutController();
  final goalsController = GoalsController();
  final dashboardController = DashboardController();
  final nutritionController = NutritionController();
  final hydrationController = HydrationController();
  final meditationController = MeditationController();
  final authController = AuthController();

  // Root / Health Check
  router.get('/', (Request req) {
    return Response.ok(
      json.encode({'status': 'online', 'message': 'OmniFit API is running correctly'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Workout Endpoints
  router.post('/api/save-workout', workoutController.saveWorkout);
  router.get('/api/get-workout', workoutController.getWorkouts);
  router.delete('/api/delete-workout', workoutController.deleteWorkout);

  // Auth Endpoints
  router.post('/api/auth/login', authController.login);
  router.post('/api/auth/register', authController.register);

  // Fitness Goals Endpoints (Sets per muscle group)
  router.post('/api/goals', goalsController.saveGoal);
  router.get('/api/goals', goalsController.getGoals);

  // Dashboard / Recommendation Engine Endpoint
  router.get('/api/dashboard', dashboardController.getDashboard);

  // Nutrition Endpoints
  router.post('/api/nutrition', nutritionController.saveNutrition);
  router.get('/api/nutrition', nutritionController.getNutrition);
  router.post('/api/nutrition-goal', nutritionController.saveNutritionGoal);
  router.get('/api/nutrition-goal', nutritionController.getNutritionGoal);

  // Hydration Endpoints
  router.post('/api/hydration', hydrationController.saveHydration);
  router.get('/api/hydration', hydrationController.getHydration);
  router.post('/api/hydration-goal', hydrationController.saveHydrationGoal);
  router.get('/api/hydration-goal', hydrationController.getHydrationGoal);

  // Meditation Endpoints
  router.post('/api/meditation', meditationController.saveMeditation);
  router.get('/api/meditation', meditationController.getMeditation);
  router.post('/api/meditation-goal', meditationController.saveMeditationGoal);
  router.get('/api/meditation-goal', meditationController.getMeditationGoal);

  return router;
}
