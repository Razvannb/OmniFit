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
    ..post('/api/goals', _saveGoalHandler)
    ..get('/api/goals', _getGoalsHandler)
    ..get('/api/dashboard', _getDashboardHandler)
    ..post('/api/nutrition', _saveNutritionHandler)
    ..get('/api/nutrition', _getNutritionHandler)
    ..post('/api/nutrition-goal', _saveNutritionGoalHandler)
    ..get('/api/nutrition-goal', _getNutritionGoalHandler)
    ..post('/api/hydration', _saveHydrationHandler)
    ..get('/api/hydration', _getHydrationHandler)
    ..post('/api/hydration-goal', _saveHydrationGoalHandler)
    ..get('/api/hydration-goal', _getHydrationGoalHandler)
    ..post('/api/meditation', _saveMeditationHandler)
    ..get('/api/meditation', _getMeditationHandler)
    ..post('/api/meditation-goal', _saveMeditationGoalHandler)
    ..get('/api/meditation-goal', _getMeditationGoalHandler);

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
          "Attention! You have had very intense workouts recently (average RPE: ${avgRpe.toStringAsFixed(1)}/10). We recommend a day of active recovery, stretching, or yoga today!";
    } else if (laggingMuscle.isNotEmpty) {
      recommendation =
          "You feel good (RPE: ${avgRpe.toStringAsFixed(1)}/10). Today would be ideal for doing a workout for '$laggingMuscle' to reach your weekly set goal!";
    } else {
      recommendation =
          "You are a champion! The RPE is optimal and you have already reached all your weekly set goals. You can do any workout you want today!";
    }

    return Response.ok(
      json.encode({'recommendation': recommendation}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Error at Dashboard: $e");
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
        body: json.encode({'error': 'Missing workout ID.'}),
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
        'message': 'Workout deleted successfully!',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Error at deletion: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// --- HANDLER SALVARE NUTRITIE (POST) ---
Future<Response> _saveNutritionHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final mealName = data['meal_name'] ?? 'Meal';
    final calories = data['calories'] ?? 0;
    final proteins = data['proteins'] ?? 0;
    final carbs = data['carbs'] ?? 0;
    final fats = data['fats'] ?? 0;
    final date = data['date'] ?? DateTime.now().toIso8601String();

    await conn.query(
      'INSERT INTO NutritionLog (user_id, meal_name, calories, proteins, carbs, fats, date_logged) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        userId,
        mealName,
        calories,
        proteins,
        carbs,
        fats,
        DateTime.parse(date).toUtc(),
      ],
    );

    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    print("Error saving nutrition: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER EXTRAGERE NUTRITIE (GET) ---
Future<Response> _getNutritionHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';

    var logs = await conn.query(
      'SELECT * FROM NutritionLog WHERE user_id = ? ORDER BY date_logged DESC',
      [userId],
    );

    List<Map<String, dynamic>> results = [];
    for (var row in logs) {
      results.add({
        'id': row['id'].toString(),
        'meal_name': row['meal_name'] ?? 'Meal',
        'calories': row['calories'],
        'proteins': row['proteins'],
        'carbs': row['carbs'],
        'fats': row['fats'],
        'date': (row['date_logged'] as DateTime).toIso8601String(),
      });
    }

    return Response.ok(
      json.encode(results),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Error getting nutrition: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER SALVARE GOAL NUTRITIE (POST) ---
Future<Response> _saveNutritionGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final goal = data['daily_calorie_goal'] ?? 2400;

    var existing = await conn.query(
      'SELECT id FROM NutritionGoals WHERE user_id = ?',
      [userId],
    );

    if (existing.isNotEmpty) {
      await conn.query(
        'UPDATE NutritionGoals SET daily_calorie_goal = ? WHERE user_id = ?',
        [goal, userId],
      );
    } else {
      await conn.query(
        'INSERT INTO NutritionGoals (user_id, daily_calorie_goal) VALUES (?, ?)',
        [userId, goal],
      );
    }

    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    print("Error saving nutrition goal: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER EXTRAGERE GOAL NUTRITIE (GET) ---
Future<Response> _getNutritionGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';

    var result = await conn.query(
      'SELECT daily_calorie_goal FROM NutritionGoals WHERE user_id = ?',
      [userId],
    );

    int goal = 2400;
    if (result.isNotEmpty) {
      goal = int.parse(result.first['daily_calorie_goal'].toString());
    }

    return Response.ok(
      json.encode({'daily_calorie_goal': goal}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Error getting nutrition goal: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER SALVARE HIDRATARE (POST) ---
Future<Response> _saveHydrationHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final amount = data['amount'] ?? 0;
    final date = data['date'] ?? DateTime.now().toIso8601String();

    await conn.query(
      'INSERT INTO HydrationLog (user_id, amount, date_logged) VALUES (?, ?, ?)',
      [userId, amount, DateTime.parse(date).toUtc()],
    );

    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    print("Error saving hydration: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER EXTRAGERE HIDRATARE (GET) ---
Future<Response> _getHydrationHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';

    var logs = await conn.query(
      'SELECT amount, date_logged FROM HydrationLog WHERE user_id = ? ORDER BY date_logged DESC',
      [userId],
    );

    List<Map<String, dynamic>> results = [];
    for (var row in logs) {
      results.add({
        'amount': row['amount'],
        'date': (row['date_logged'] as DateTime).toIso8601String(),
      });
    }
    return Response.ok(
      json.encode(results),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Error getting hydration: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER SALVARE GOAL HIDRATARE (POST) ---
Future<Response> _saveHydrationGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final goal = data['daily_water_goal'] ?? 2500;

    var existing = await conn.query(
      'SELECT id FROM HydrationGoals WHERE user_id = ?',
      [userId],
    );

    if (existing.isNotEmpty) {
      await conn.query(
        'UPDATE HydrationGoals SET daily_water_goal = ? WHERE user_id = ?',
        [goal, userId],
      );
    } else {
      await conn.query(
        'INSERT INTO HydrationGoals (user_id, daily_water_goal) VALUES (?, ?)',
        [userId, goal],
      );
    }
    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    print("Error saving hydration goal: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER EXTRAGERE GOAL HIDRATARE (GET) ---
Future<Response> _getHydrationGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';

    var result = await conn.query(
      'SELECT daily_water_goal FROM HydrationGoals WHERE user_id = ?',
      [userId],
    );

    int goal = 2500; // Default
    if (result.isNotEmpty) {
      goal = int.parse(result.first['daily_water_goal'].toString());
    }
    return Response.ok(
      json.encode({'daily_water_goal': goal}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Error getting hydration goal: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER SALVARE MEDITAȚIE (POST) ---
Future<Response> _saveMeditationHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final minutes = data['minutes'] ?? 0;
    final date = data['date'] ?? DateTime.now().toIso8601String();

    await conn.query(
      'INSERT INTO MeditationLog (user_id, minutes, date_logged) VALUES (?, ?, ?)',
      [userId, minutes, DateTime.parse(date).toUtc()],
    );

    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    print("Error saving meditation: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER EXTRAGERE MEDITAȚIE (GET) ---
Future<Response> _getMeditationHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';

    var logs = await conn.query(
      'SELECT minutes, date_logged FROM MeditationLog WHERE user_id = ? ORDER BY date_logged DESC',
      [userId],
    );

    List<Map<String, dynamic>> results = [];
    for (var row in logs) {
      results.add({
        'minutes': row['minutes'],
        'date': (row['date_logged'] as DateTime).toIso8601String(),
      });
    }
    return Response.ok(
      json.encode(results),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Error getting meditation: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER SALVARE GOAL MEDITAȚIE (POST) ---
Future<Response> _saveMeditationGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final goal = data['daily_minutes_goal'] ?? 30;

    var existing = await conn.query(
      'SELECT id FROM MeditationGoals WHERE user_id = ?',
      [userId],
    );

    if (existing.isNotEmpty) {
      await conn.query(
        'UPDATE MeditationGoals SET daily_minutes_goal = ? WHERE user_id = ?',
        [goal, userId],
      );
    } else {
      await conn.query(
        'INSERT INTO MeditationGoals (user_id, daily_minutes_goal) VALUES (?, ?)',
        [userId, goal],
      );
    }
    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    print("Error saving meditation goal: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- HANDLER EXTRAGERE GOAL MEDITAȚIE (GET) ---
Future<Response> _getMeditationGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';

    var result = await conn.query(
      'SELECT daily_minutes_goal FROM MeditationGoals WHERE user_id = ?',
      [userId],
    );

    int goal = 30; // Default
    if (result.isNotEmpty) {
      goal = int.parse(result.first['daily_minutes_goal'].toString());
    }
    return Response.ok(
      json.encode({'daily_minutes_goal': goal}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Error getting meditation goal: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}
