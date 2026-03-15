import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:omnifit_backend/db/database.dart';

void main(List<String> args) async {
  // Router Configuration
  final router = Router()
    ..get('/', _rootHandler)
    ..post('/api/save-workout', _saveWorkoutHandler)
    ..get('/api/get-workout', _getWorkoutHandler)
    ..delete('/api/delete-workout', _deleteWorkoutHandler)
    ..post('/api/auth/login', _placeholderHandler)
    ..post('/api/hydration', _placeholderHandler)
    ..post('/api/goals', _saveGoalHandler)
    ..get('/api/goals', _getGoalsHandler)
    ..get('/api/dashboard', _getDashboardHandler);

  // IP and port configuration
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // Pipeline-ul with Middleware for login
  final pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // Starting the server
  final server = await serve(pipeline, ip, port);
  print(
    '🔥 The OmniFit Server is ONLINE at http://${server.address.host}:${server.port}',
  );
}

// --- HANDLER ROOT (Health Check) ---
Response _rootHandler(Request req) {
  return Response.ok(
    json.encode({'status': 'online', 'message': 'OmniFit API rulează corect'}),
    headers: {'Content-Type': 'application/json'},
  );
}

//HANDLER PLACEHOLDER
Future<Response> _placeholderHandler(Request req) async {
  return Response.ok(
    json.encode({
      'status': 'coming_soon',
      'message': 'Acest endpoint va fi implementat în curând.',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

// Save and edit workout handler
Future<Response> _saveWorkoutHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final incomingId =
        data['id']; // Poate fi null (nou) sau un ID existent (editare)
    final userId = data['user_id'] ?? 1;
    final workoutName = data['workoutName'] ?? 'Fără nume';
    final date = data['date'] ?? DateTime.now().toIso8601String();
    final rpe = data['rpe'] ?? 5.0;
    final List<dynamic>? exercises = data['exercises'];

    int currentWorkoutId;

    if (incomingId != null && !incomingId.toString().contains('#')) {
      // If there's an edit we update
      currentWorkoutId = int.parse(incomingId.toString());
      await conn.query(
        'UPDATE Workouts SET name = ?, rpe = ?, date_created = ? WHERE id = ?',
        [workoutName, rpe, DateTime.parse(date).toUtc(), currentWorkoutId],
      );

      // We delete the old exercises to replace with the new ones
      await conn.query('DELETE FROM Sets WHERE workoutID = ?', [
        currentWorkoutId,
      ]);
    } else {
      var result = await conn.query(
        'INSERT INTO Workouts (user_id, name, rpe, date_created) VALUES (?, ?, ?, ?)',
        [userId, workoutName, rpe, DateTime.parse(date).toUtc()],
      );
      currentWorkoutId = result.insertId!;
    }

    // Inserting Exercises
    if (exercises != null) {
      for (var ex in exercises) {
        await conn.query(
          'INSERT INTO Sets (workoutID, exerciseName, muscleGroup, setsCount, reps, recoveryBetweenSets, recoveryExercise) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            currentWorkoutId,
            ex['exerciseName'],
            ex['muscleGroup'],
            ex['sets'],
            ex['reps'],
            ex['recoveryBetweenSets'],
            ex['recoveryExercise'],
          ],
        );
      }
    }

    return Response.ok(
      json.encode({'status': 'success', 'workout_id': currentWorkoutId}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Eroare la salvare: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// Get Workout Handler
Future<Response> _getWorkoutHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';
    List<Map<String, dynamic>> finalWorkouts = [];

    // We search for the user's workouts
    var workouts = await conn.query(
      'SELECT * FROM Workouts WHERE user_id = ? ORDER BY date_created DESC',
      [userId],
    );

    for (var w in workouts) {
      int workoutId = w['id'];

      // We search for the exercises in this workout
      var sets = await conn.query('SELECT * FROM Sets WHERE workoutID = ?', [
        workoutId,
      ]);

      List<Map<String, dynamic>> exercisesJson = [];
      int workoutGlobalRest = 60; // Default

      var setsList = sets.toList();
      for (var i = 0; i < setsList.length; i++) {
        var s = setsList[i];

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

      // Building the object for the frontend
      finalWorkouts.add({
        "id": workoutId,
        "workoutName": w['name'],
        "date": (w['date_created'] as DateTime).toIso8601String(),
        "rpe": w['rpe'],
        "globalRestTime": workoutGlobalRest,
        "exercises": exercisesJson,
      });
    }

    return Response.ok(
      json.encode(finalWorkouts),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Eroare la extragere: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// Handler for saving the objective
Future<Response> _saveGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final muscleGroup = data['muscleGroup'];
    final targetSets = data['targetSets'];

    // Checking if an objective already exists
    var existing = await conn.query(
      'SELECT id FROM Goals WHERE user_id = ? AND muscle_group = ?',
      [userId, muscleGroup],
    );

    if (existing.isNotEmpty) {
      await conn.query('UPDATE Goals SET target_sets = ? WHERE id = ?', [
        targetSets,
        existing.first['id'],
      ]);
    } else {
      await conn.query(
        'INSERT INTO Goals (user_id, muscle_group, target_sets) VALUES (?, ?, ?)',
        [userId, muscleGroup, targetSets],
      );
    }

    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER EXTRAGERE OBIECTIVE + CALCULARE PROGRES (GET) ---
Future<Response> _getGoalsHandler(Request req) async {
  try {
    final conn = await Database.connect();
    // Ne asigurăm că user_id e corect convertit în INT pentru MySQL
    final userId = int.tryParse(req.url.queryParameters['user_id'] ?? '1') ?? 1;

    var goals = await conn.query('SELECT * FROM Goals WHERE user_id = ?', [
      userId,
    ]);
    List<Map<String, dynamic>> finalGoals = [];

    for (var g in goals) {
      String muscle = g['muscle_group'].toString();
      int target = int.tryParse(g['target_sets'].toString()) ?? 0;

      var progressQuery = await conn.query(
        '''
        SELECT SUM(s.setsCount) as total 
        FROM Sets s 
        JOIN Workouts w ON s.workoutID = w.id 
        WHERE w.user_id = ? AND s.muscleGroup = ? AND w.date_created >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
      ''',
        [userId, muscle],
      );

      int currentSets = 0;
      if (progressQuery.isNotEmpty && progressQuery.first['total'] != null) {
        // AICI ERA PROBLEMA: SUM-ul vine cu zecimale de la MySQL (ex: 4.0)
        currentSets = double.parse(
          progressQuery.first['total'].toString(),
        ).toInt();
      }

      finalGoals.add({
        'id': g['id'].toString(),
        'muscleGroup': muscle,
        'targetSets': target,
        'currentSets': currentSets,
      });
    }
    return Response.ok(
      json.encode(finalGoals),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Eroare la GET Goals: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER MOTOR DE RECOMANDĂRI (GET) ---
Future<Response> _getDashboardHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = int.tryParse(req.url.queryParameters['user_id'] ?? '1') ?? 1;

    var rpeQuery = await conn.query(
      '''
      SELECT AVG(rpe) as avg_rpe FROM (SELECT rpe FROM Workouts WHERE user_id = ? ORDER BY date_created DESC LIMIT 3) as sub
    ''',
      [userId],
    );

    double avgRpe = 5.0;
    if (rpeQuery.isNotEmpty && rpeQuery.first['avg_rpe'] != null) {
      avgRpe = double.parse(rpeQuery.first['avg_rpe'].toString());
    }

    var goals = await conn.query('SELECT * FROM Goals WHERE user_id = ?', [
      userId,
    ]);
    String laggingMuscle = "";

    for (var g in goals) {
      String muscle = g['muscle_group'].toString();
      int target = int.tryParse(g['target_sets'].toString()) ?? 0;

      var progressQuery = await conn.query(
        'SELECT SUM(s.setsCount) as total FROM Sets s JOIN Workouts w ON s.workoutID = w.id WHERE w.user_id = ? AND s.muscleGroup = ? AND w.date_created >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)',
        [userId, muscle],
      );

      int currentSets = 0;
      if (progressQuery.isNotEmpty && progressQuery.first['total'] != null) {
        currentSets = double.parse(
          progressQuery.first['total'].toString(),
        ).toInt();
      }

      if (currentSets < target) {
        laggingMuscle = muscle;
        break;
      }
    }

    String recommendation = "";
    if (avgRpe >= 8.0) {
      recommendation =
          "Atenție! Ai avut antrenamente foarte intense recent (RPE mediu: ${avgRpe.toStringAsFixed(1)}/10). Îți recomandăm o zi de recuperare activă, stretching sau yoga azi!";
    } else if (laggingMuscle.isNotEmpty) {
      recommendation =
          "Te simți bine (RPE: ${avgRpe.toStringAsFixed(1)}/10). Astăzi ar fi ideal să faci un antrenament pentru '$laggingMuscle' pentru a-ți atinge obiectivul săptămânal de seturi!";
    } else {
      recommendation =
          "Ești un campion! RPE-ul e optim și ai atins deja toate obiectivele săptămânale de volum. Poți face orice antrenament dorești azi!";
    }

    return Response.ok(
      json.encode({'recommendation': recommendation}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Eroare la Dashboard: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER ȘTERGERE ANTRENAMENT (DELETE) ---
Future<Response> _deleteWorkoutHandler(Request req) async {
  try {
    final workoutId = req.url.queryParameters['id'];
    if (workoutId == null) {
      return Response.badRequest(
        body: json.encode({'error': 'Lipsește ID-ul antrenamentului.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final conn = await Database.connect();

    // Ștergem Antrenamentul
    // (Exercițiile din tabela Sets se vor șterge automat datorită ON DELETE CASCADE setat in SQL)
    await conn.query('DELETE FROM Workouts WHERE id = ?', [workoutId]);

    return Response.ok(
      json.encode({
        'status': 'deleted',
        'message': 'Antrenamentul a fost șters!',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Eroare la ștergere: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
