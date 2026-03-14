import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Importăm fișierul care comunică direct cu baza de date MySQL
import 'database_dao.dart'; 

// 1. Configurăm rutele (Endpoint-urile)
final router = Router()
  ..get('/', _rootHandler)
  ..post('/api/auth/login', _loginHandler)
  ..post('/api/workouts', _createWorkoutHandler)
  ..post('/api/rpe', _logRpeHandler)
  ..post('/api/hydration', _logHydrationHandler) 
  ..post('/api/nutrition', _logNutritionHandler) 
  ..post('/api/goals', _setGoalHandler);         

// Răspuns de test
Response _rootHandler(Request req) {
  return Response.ok('Serverul OmniFit este UP și CONECTAT LA DB!\n');
}

// Logica de Login (Mock-up)
Future<Response> _loginHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final email = data['email'];
    final password = data['password'];

    if (email != null && password != null) {
      return Response.ok(
        json.encode({'status': 'success', 'message': 'Te-ai logat cu succes!', 'token': 'mock_token_hackathon_123'}),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      return Response.badRequest(
        body: json.encode({'status': 'error', 'message': 'Email sau parola incorecte'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  } catch (e) {
    return Response.internalServerError(body: 'Eroare de server: $e');
  }
}

// 2. Logica pentru Salvarea Antrenamentelor (F1)
Future<Response> _createWorkoutHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'];
    final List<dynamic>? sets = data['sets']; 

    if (userId == null || sets == null || sets.isEmpty) {
       return Response.badRequest(
        body: json.encode({'status': 'error', 'message': 'Date incomplete (lipseste user_id sau sets).'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    for (var setRecord in sets) {
      if (setRecord['exerciseName'] == null || setRecord['setOrder'] == null || setRecord['reps'] == null) {
        return Response.badRequest(
          body: json.encode({'status': 'error', 'message': 'Set invalid. Verifica exerciseName, setOrder si reps.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    }

    // --- CONEXIUNEA REALĂ CU BAZA DE DATE ---
    int newWorkoutId = await DatabaseDAO.createWorkout(userId);
    await DatabaseDAO.insertSets(newWorkoutId, sets);

    return Response.ok(
      json.encode({'status': 'success', 'message': 'Antrenamentul a fost salvat in MySQL!', 'setsProcessed': sets.length}),
      headers: {'Content-Type': 'application/json'},
    );

  } catch (e) {
    return Response.internalServerError(body: json.encode({'error': 'Eroare de procesare: $e'}));
  }
}

// 3. Logica pentru Evaluarea Efortului (F3 + F5)
Future<Response> _logRpeHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final workoutId = data['workout_id']; 
    final rpeValue = data['rpe_value'];   

    if (workoutId == null || rpeValue == null) {
       return Response.badRequest(
        body: json.encode({'status': 'error', 'message': 'Date incomplete (lipseste workout_id sau rpe_value).'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (rpeValue < 1 || rpeValue > 10) {
       return Response.badRequest(
        body: json.encode({'status': 'error', 'message': 'RPE trebuie sa fie o nota de la 1 la 10.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    String feedbackMessage = "";
    if (rpeValue <= 4) {
      feedbackMessage = "Antrenament ușor! Data viitoare încearcă să crești volumul.";
    } else if (rpeValue >= 5 && rpeValue <= 7) {
      feedbackMessage = "Efort solid! Ești în zona optimă pentru creștere musculară.";
    } else if (rpeValue >= 8 && rpeValue <= 9) {
      feedbackMessage = "Antrenament intens! Hidratează-te bine.";
    } else if (rpeValue == 10) {
      feedbackMessage = "Efort MAXIM! Odihnește-te pentru recuperare.";
    }

    // --- CONEXIUNEA REALĂ CU BAZA DE DATE ---
    await DatabaseDAO.insertRpe(workoutId, rpeValue);

    return Response.ok(
      json.encode({'status': 'success', 'message': 'RPE salvat cu succes!', 'ai_feedback': feedbackMessage}),
      headers: {'Content-Type': 'application/json'},
    );

  } catch (e) {
    return Response.internalServerError(body: json.encode({'error': 'Eroare de procesare: $e'}));
  }
}

// 4. Logica pentru Hidratare (F7)
Future<Response> _logHydrationHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'];
    final ml = data['ml']; 

    if (userId == null || ml == null) {
       return Response.badRequest(body: json.encode({'status': 'error', 'message': 'Date incomplete.'}));
    }

    // --- CONEXIUNEA REALĂ CU BAZA DE DATE ---
    await DatabaseDAO.insertHydration(userId, ml);

    return Response.ok(json.encode({'status': 'success', 'message': '${ml}ml de apa salvati in MySQL!'}));
  } catch (e) {
    return Response.internalServerError(body: json.encode({'error': 'Eroare: $e'}));
  }
}

// 5. Logica pentru Nutriție (F9)
Future<Response> _logNutritionHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'];
    final calories = data['calories'];

    if (userId == null || calories == null) {
       return Response.badRequest(body: json.encode({'status': 'error', 'message': 'Date incomplete.'}));
    }

    // --- CONEXIUNEA REALĂ CU BAZA DE DATE ---
    await DatabaseDAO.insertNutrition(userId, calories);

    return Response.ok(json.encode({'status': 'success', 'message': '${calories} kcal salvate in MySQL!'}));
  } catch (e) {
    return Response.internalServerError(body: json.encode({'error': 'Eroare: $e'}));
  }
}

// 6. Logica pentru Obiective (F2)
Future<Response> _setGoalHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'];
    final muscleGroup = data['muscle_group'];
    final targetSets = data['target_sets'];

    if (userId == null || muscleGroup == null || targetSets == null) {
       return Response.badRequest(body: json.encode({'status': 'error', 'message': 'Date incomplete.'}));
    }

    // --- CONEXIUNEA REALĂ CU BAZA DE DATE ---
    await DatabaseDAO.insertGoal(userId, muscleGroup, targetSets);

    return Response.ok(json.encode({'status': 'success', 'message': 'Obiectivul a fost salvat in MySQL!'}));
  } catch (e) {
    return Response.internalServerError(body: json.encode({'error': 'Eroare: $e'}));
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