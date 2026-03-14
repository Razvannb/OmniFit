import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Importurile din proiectul tău
import 'package:omnifit_backend/db/database.dart';

void main(List<String> args) async {
  // Configurarea Routerului
  final router = Router()
    ..get('/', _rootHandler)
    ..post('/api/save-workout', _saveWorkoutHandler)
    ..get('/api/get-workout', _getWorkoutHandler)
    ..post('/api/auth/login', _placeholderHandler)
    ..post('/api/hydration', _placeholderHandler)
    ..post('/api/nutrition', _placeholderHandler)
    ..post('/api/goals', _placeholderHandler);

  // Configurarea IP-ului și Portului
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // Pipeline-ul cu Middleware pentru logare
  final pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // Pornirea Serverului
  final server = await serve(pipeline, ip, port);
  print('🔥 Serverul OmniFit este ONLINE pe http://${server.address.host}:${server.port}');
}

// --- HANDLER ROOT (Health Check) ---
Response _rootHandler(Request req) {
  return Response.ok(
    json.encode({'status': 'online', 'message': 'OmniFit API rulează corect'}),
    headers: {'Content-Type': 'application/json'},
  );
}

// --- HANDLER PLACEHOLDER (Pentru rutele neimplementate încă) ---
Future<Response> _placeholderHandler(Request req) async {
  return Response.ok(
    json.encode({'status': 'coming_soon', 'message': 'Acest endpoint va fi implementat în curând.'}),
    headers: {'Content-Type': 'application/json'},
  );
}

// --- HANDLER SALVARE ANTRENAMENT (POST) ---
Future<Response> _saveWorkoutHandler(Request req) async {
  final conn = await Database.connect(); // Deschidem conexiunea la început
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final workoutName = data['workoutName'] ?? 'Fără nume';
    final date = data['date'] ?? DateTime.now().toIso8601String();
    final rpe = data['rpe'] ?? 5.0;
    final List<dynamic>? exercises = data['exercises'];

    // 1. Inserăm Antrenamentul
    var result = await conn.query(
      'INSERT INTO Workouts (user_id, name, rpe, date_created) VALUES (?, ?, ?, ?)',
      [userId, workoutName, rpe, DateTime.parse(date)]
    );
    
    int newWorkoutId = result.insertId!; 

    // 2. Inserăm Exercițiile
    if (exercises != null) {
      for (var ex in exercises) {
        await conn.query(
          'INSERT INTO Sets (workoutID, exerciseName, muscleGroup, setsCount, reps, recoveryBetweenSets, recoveryExercise) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            newWorkoutId, 
            ex['exerciseName'], 
            ex['muscleGroup'], 
            ex['sets'], 
            ex['reps'], 
            ex['recoveryBetweenSets'], 
            ex['recoveryExercise']
          ]
        );
      }
    }

    // Returnăm succesul
    return Response.ok(json.encode({
      'status': 'success', 
      'workout_id': newWorkoutId
    }), headers: {'Content-Type': 'application/json'});

  } catch (e) {
    print("Eroare la salvare: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'}
    );
  } finally {
    await conn.close(); // Se execută mereu
  }
}

// --- HANDLER EXTRAGERE ANTRENAMENTE (GET) ---
Future<Response> _getWorkoutHandler(Request req) async {
  final conn = await Database.connect();
  try {
    final userId = req.url.queryParameters['user_id'] ?? '1';
    List<Map<String, dynamic>> finalWorkouts = [];

    // 1. Căutăm antrenamentele userului
    var workouts = await conn.query(
      'SELECT * FROM Workouts WHERE user_id = ? ORDER BY date_created DESC',
      [userId]
    );

    for (var w in workouts) {
      int workoutId = w['id'];
      
      // 2. Căutăm exercițiile (Sets) pentru acest antrenament
      var sets = await conn.query(
        'SELECT * FROM Sets WHERE workoutID = ?',
        [workoutId]
      );

      List<Map<String, dynamic>> exercisesJson = [];
      int workoutGlobalRest = 60; // Default

      var setsList = sets.toList();
      for (var i = 0; i < setsList.length; i++) {
        var s = setsList[i];
        
        // Luăm timpul de pauză de la primul exercițiu pentru "Global Rest Time"
        if (i == 0) {
          workoutGlobalRest = s['recoveryBetweenSets'] ?? 60;
        }

        exercisesJson.add({
          "exerciseName": s['exerciseName'],
          "muscleGroup": s['muscleGroup'],
          "sets": s['setsCount'],
          "reps": s['reps'],
          "recoveryBetweenSets": s['recoveryBetweenSets'],
          "recoveryExercise": s['recoveryExercise'],
        });
      }

      // 3. Construim obiectul pentru Frontend
      finalWorkouts.add({
        "id": workoutId,
        "workoutName": w['name'],
        "date": (w['date_created'] as DateTime).toIso8601String(),
        "rpe": w['rpe'],
        "globalRestTime": workoutGlobalRest,
        "exercises": exercisesJson
      });
    }

    return Response.ok(
      json.encode(finalWorkouts),
      headers: {'Content-Type': 'application/json'}
    );
  } catch (e) {
    print("Eroare la extragere: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'}
    );
  } finally {
    await conn.close();
  }
}