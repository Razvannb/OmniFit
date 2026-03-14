import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// --- IMPORTURILE REALE DIN PROIECTUL VOSTRU ---
import 'package:omnifit_backend/db/database.dart';
import 'package:omnifit_backend/dao/workout_dao.dart';
import 'package:omnifit_backend/dao/sets_dao.dart';
import 'package:omnifit_backend/dao/rpe_log_dao.dart';
import 'package:omnifit_backend/dao/hydration_dao.dart';
import 'package:omnifit_backend/dao/nutrition_dao.dart';
import 'package:omnifit_backend/dao/goal_dao.dart';

// Importăm și modelele necesare pentru DAO-uri
import 'package:omnifit_backend/models/sets.dart';
import 'package:omnifit_backend/models/rpe_log.dart';
import 'package:omnifit_backend/models/hydration_log.dart';
import 'package:omnifit_backend/models/nutrition_log.dart';
import 'package:omnifit_backend/models/goal.dart';

// 1. Configurăm rutele
final router = Router()
  ..get('/', _rootHandler)
  ..post('/api/auth/login', _loginHandler)
  ..post('/api/workouts', _createWorkoutHandler)
  ..post('/api/rpe', _logRpeHandler)
  ..post('/api/hydration', _logHydrationHandler)
  ..post('/api/nutrition', _logNutritionHandler)
  ..post('/api/goals', _setGoalHandler);

Response _rootHandler(Request req) {
  return Response.ok('Serverul OmniFit este UP și CONECTAT LA DB!\n');
}

Future<Response> _loginHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);
    if (data['email'] != null && data['password'] != null) {
      return Response.ok(
        json.encode({'status': 'success', 'message': 'Te-ai logat cu succes!', 'token': 'mock_token'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return Response.badRequest(body: json.encode({'error': 'Email/parola incorecte'}));
  } catch (e) {
    return Response.internalServerError(body: 'Eroare: $e');
  }
}

// 2. Salvarea Antrenamentelor (F1)
Future<Response> _createWorkoutHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'];
    final List<dynamic>? sets = data['sets'];

    if (userId == null || sets == null || sets.isEmpty) {
      return Response.badRequest(body: json.encode({'error': 'Date incomplete.'}));
    }

    // --- CONEXIUNEA CU BAZA DE DATE ---
    final conn = await Database.connect();
    try {
      final workoutDao = WorkoutDao(conn);
      final setDao = SetDao(conn);

      // 1. Creăm antrenamentul
      int newWorkoutId = await workoutDao.createWorkout(userId);

      // 2. Adăugăm fiecare set folosind modelul ExerciseSet
      for (var setRecord in sets) {
        // ATENȚIE: Dacă îți dă eroare cu roșu la `workoutId:`, șterge etichetele și lasă doar valorile, 
        // ex: ExerciseSet(newWorkoutId, setRecord['exerciseName'], ...)
        final exerciseSet = ExerciseSet(
          workoutId: newWorkoutId,
          exerciseName: setRecord['exerciseName'],
          setOrder: setRecord['setOrder'],
          reps: setRecord['reps'],
          weight: setRecord['weight'] ?? 0.0,
          recoveryBetweenSets: setRecord['recoveryBetweenSets'] ?? 60,
          recoveryExercise: setRecord['recoveryExercise'] ?? 60,
        );
        await setDao.addSet(exerciseSet);
      }
    } finally {
      await conn.close(); 
    }

    return Response.ok(json.encode({'status': 'success', 'message': 'Antrenament salvat!'}));
  } catch (e) {
    return Response.internalServerError(body: json.encode({'error': 'Eroare: $e'}));
  }
}

// 3. Evaluarea Efortului (F3 + F5)
Future<Response> _logRpeHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final workoutId = data['workout_id'];
    final rpeValue = data['rpe_value'];

    if (workoutId == null || rpeValue == null) return Response.badRequest(body: 'Date incomplete');

    String feedbackMessage = rpeValue >= 8 ? "Antrenament intens!" : "Efort solid!";

    // --- CONEXIUNEA CU BAZA DE DATE ---
    final conn = await Database.connect();
    try {
      final rpeDao = RpeLogDao(conn);
      final rpeLog = RpeLog(workoutId: workoutId, rpeValue: rpeValue);
      await rpeDao.addRpeLog(rpeLog);
    } finally {
      await conn.close();
    }

    return Response.ok(json.encode({'status': 'success', 'ai_feedback': feedbackMessage}));
  } catch (e) {
    return Response.internalServerError(body: 'Eroare: $e');
  }
}

// 4. Hidratare (F7)
Future<Response> _logHydrationHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'];
    final ml = data['ml'];

    if (userId == null || ml == null) return Response.badRequest(body: 'Date incomplete');

    // --- CONEXIUNEA CU BAZA DE DATE ---
    final conn = await Database.connect();
    try {
      final hydrationDao = HydrationDao(conn);
      final log = HydrationLog(userId: userId, waterMl: ml); 
      await hydrationDao.addHydration(log);
    } finally {
      await conn.close();
    }

    return Response.ok(json.encode({'status': 'success', 'message': '${ml}ml salvati!'}));
  } catch (e) {
    return Response.internalServerError(body: 'Eroare: $e');
  }
}

// 5. Nutriție (F9)
Future<Response> _logNutritionHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'];
    final calories = data['calories'];

    if (userId == null || calories == null) return Response.badRequest(body: 'Date incomplete');

    // --- CONEXIUNEA CU BAZA DE DATE ---
    final conn = await Database.connect();
    try {
      final nutritionDao = NutritionDao(conn);
      final log = NutritionLog(userId: userId, calories: calories);
      await nutritionDao.addNutrition(log);
    } finally {
      await conn.close();
    }

    return Response.ok(json.encode({'status': 'success', 'message': '${calories} kcal salvate!'}));
  } catch (e) {
    return Response.internalServerError(body: 'Eroare: $e');
  }
}

// 6. Obiective (F2)
Future<Response> _setGoalHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'];
    final muscleGroup = data['muscle_group'];
    final targetSets = data['target_sets'];

    if (userId == null || muscleGroup == null || targetSets == null) return Response.badRequest();

    // --- CONEXIUNEA CU BAZA DE DATE ---
    final conn = await Database.connect();
    try {
      final goalDao = GoalDao(conn);
      final goal = Goal(userId: userId, muscleGroup: muscleGroup, targetSets: targetSets);
      await goalDao.addGoal(goal);
    } finally {
      await conn.close();
    }

    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    return Response.internalServerError(body: 'Eroare: $e');
  }
}

// Pornirea serverului
void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final pipeline = Pipeline().addMiddleware(logRequests()).addHandler(router.call);
  final server = await serve(pipeline, ip, port);
  print('🔥 Backend-ul OmniFit rulează pe http://${server.address.host}:${server.port}');
}