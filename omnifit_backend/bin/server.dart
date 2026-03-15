import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:omnifit_backend/db/database.dart';

void main(List<String> args) async {
  // --- Router Configuration ---
  // Maps HTTP requests (GET, POST, DELETE) to their specific handler functions.
  // Think of this as the "switchboard" of your backend.
  final router = Router()
    ..get('/', _rootHandler)
    // Workout Endpoints
    ..post('/api/save-workout', _saveWorkoutHandler)
    ..get('/api/get-workout', _getWorkoutHandler)
    ..delete('/api/delete-workout', _deleteWorkoutHandler)
    // Auth Endpoint
    ..post('/api/auth/login', _placeholderHandler)
    // Fitness Goals Endpoints (Sets per muscle group)
    ..post('/api/goals', _saveGoalHandler)
    ..get('/api/goals', _getGoalsHandler)
    // Dashboard / Recommendation Engine Endpoint
    ..get('/api/dashboard', _getDashboardHandler)
    // Nutrition Endpoints
    ..post('/api/nutrition', _saveNutritionHandler)
    ..get('/api/nutrition', _getNutritionHandler)
    ..post('/api/nutrition-goal', _saveNutritionGoalHandler)
    ..get('/api/nutrition-goal', _getNutritionGoalHandler)
    // Hydration Endpoints
    ..post('/api/hydration', _saveHydrationHandler)
    ..get('/api/hydration', _getHydrationHandler)
    ..post('/api/hydration-goal', _saveHydrationGoalHandler)
    ..get('/api/hydration-goal', _getHydrationGoalHandler)
    // Meditation Endpoints
    ..post('/api/meditation', _saveMeditationHandler)
    ..get('/api/meditation', _getMeditationHandler)
    ..post('/api/meditation-goal', _saveMeditationGoalHandler)
    ..get('/api/meditation-goal', _getMeditationGoalHandler);

  // --- Server Configuration ---
  // Listen on all available network interfaces (0.0.0.0)
  final ip = InternetAddress.anyIPv4;
  // Use the port from the environment variable, or fallback to 8080
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // --- Pipeline Configuration ---
  // A pipeline processes the request before it reaches the router.
  // logRequests() automatically prints every incoming request to the console.
  final pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // --- Start Server ---
  final server = await serve(pipeline, ip, port);
  print(
    '🔥 The OmniFit Server is ONLINE at http://${server.address.host}:${server.port}',
  );
}

// ==========================================
//          SYSTEM / AUTH HANDLERS
// ==========================================

// --- ROOT HANDLER (Health Check) ---
// Used to verify if the server is up and running.
Response _rootHandler(Request req) {
  return Response.ok(
    json.encode({'status': 'online', 'message': 'OmniFit API is running correctly'}),
    headers: {'Content-Type': 'application/json'},
  );
}

// --- PLACEHOLDER AUTH HANDLER ---
// Will handle user login in the future.
Future<Response> _placeholderHandler(Request req) async {
  return Response.ok(
    json.encode({
      'status': 'coming_soon',
      'message': 'This endpoint will be implemented soon.',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

// ==========================================
//            WORKOUT HANDLERS
// ==========================================

// --- SAVE / UPDATE WORKOUT (POST) ---
// Handles both creating a new workout and updating an existing one.
Future<Response> _saveWorkoutHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final incomingId = data['id']; // Can be null (new) or an existing ID (edit)
    final userId = data['user_id'] ?? 1;
    final workoutName = data['workoutName'] ?? 'Unnamed Workout';
    final date = data['date'] ?? DateTime.now().toIso8601String();
    final rpe = data['rpe'] ?? 5.0; // RPE = Rate of Perceived Exertion (Intensity)
    final List<dynamic>? exercises = data['exercises'];

    int currentWorkoutId;

    if (incomingId != null && !incomingId.toString().contains('#')) {
      // SCENARIO 1: EDIT EXISTING WORKOUT
      currentWorkoutId = int.parse(incomingId.toString());
      
      // Update the main workout details
      await conn.query(
        'UPDATE Workouts SET name = ?, rpe = ?, date_created = ? WHERE id = ?',
        [workoutName, rpe, DateTime.parse(date).toUtc(), currentWorkoutId],
      );

      // Delete the old exercises to replace them entirely with the updated list
      await conn.query('DELETE FROM Sets WHERE workoutID = ?', [currentWorkoutId]);
    } else {
      // SCENARIO 2: CREATE NEW WORKOUT
      var result = await conn.query(
        'INSERT INTO Workouts (user_id, name, rpe, date_created) VALUES (?, ?, ?, ?)',
        [userId, workoutName, rpe, DateTime.parse(date).toUtc()],
      );
      currentWorkoutId = result.insertId!; // Get the newly generated Database ID
    }

    // Insert all exercises associated with this workout into the 'Sets' table
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
    print("Error saving workout: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// --- GET ALL WORKOUTS (GET) ---
// Retrieves a user's entire workout history, including nested exercises.
Future<Response> _getWorkoutHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';
    List<Map<String, dynamic>> finalWorkouts = [];

    // 1. Fetch all parent workouts for this user, newest first
    var workouts = await conn.query(
      'SELECT * FROM Workouts WHERE user_id = ? ORDER BY date_created DESC',
      [userId],
    );

    for (var w in workouts) {
      int workoutId = w['id'];

      // 2. Fetch all child exercises (sets) that belong to this specific workout
      var sets = await conn.query('SELECT * FROM Sets WHERE workoutID = ?', [workoutId]);

      List<Map<String, dynamic>> exercisesJson = [];
      int workoutGlobalRest = 60; // Default rest time

      var setsList = sets.toList();
      for (var i = 0; i < setsList.length; i++) {
        var s = setsList[i];

        // Assume the first exercise dictates the global rest time
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

      // 3. Assemble the final JSON structure for the frontend
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
    print("Error fetching workouts: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// --- DELETE WORKOUT (DELETE) ---
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

    // Delete the Workout. 
    // (The associated exercises in the 'Sets' table will be deleted automatically 
    // if 'ON DELETE CASCADE' is configured in the SQL database schema).
    await conn.query('DELETE FROM Workouts WHERE id = ?', [workoutId]);

    return Response.ok(
      json.encode({
        'status': 'deleted',
        'message': 'Workout deleted successfully!',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Error deleting workout: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// ==========================================
//          GOALS & DASHBOARD AI
// ==========================================

// --- SAVE WEEKLY SET GOAL (POST) ---
Future<Response> _saveGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final muscleGroup = data['muscleGroup']; // e.g., 'Chest', 'Back'
    final targetSets = data['targetSets'];

    // Check if the user already has a goal set for this specific muscle
    var existing = await conn.query(
      'SELECT id FROM Goals WHERE user_id = ? AND muscle_group = ?',
      [userId, muscleGroup],
    );

    if (existing.isNotEmpty) {
      // Update existing goal
      await conn.query('UPDATE Goals SET target_sets = ? WHERE id = ?', [
        targetSets,
        existing.first['id'],
      ]);
    } else {
      // Insert new goal
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

// --- GET GOALS + CALCULATE WEEKLY PROGRESS (GET) ---
// Retrieves target sets and calculates how many sets the user actually did in the last 7 days.
Future<Response> _getGoalsHandler(Request req) async {
  try {
    final conn = await Database.connect();
    // Ensure user_id is properly cast to an Integer for MySQL safety
    final userId = int.tryParse(req.url.queryParameters['user_id'] ?? '1') ?? 1;

    // Fetch user's set targets
    var goals = await conn.query('SELECT * FROM Goals WHERE user_id = ?', [userId]);
    List<Map<String, dynamic>> finalGoals = [];

    for (var g in goals) {
      String muscle = g['muscle_group'].toString();
      int target = int.tryParse(g['target_sets'].toString()) ?? 0;

      // SQL Magic: Sum up all sets completed for this specific muscle group 
      // in workouts logged within the last 7 days (DATE_SUB(CURDATE(), INTERVAL 7 DAY)).
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
        currentSets = double.parse(progressQuery.first['total'].toString()).toInt();
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
    print("Error getting Goals: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
    );
  }
}

// --- DASHBOARD RECOMMENDATION ENGINE (GET) ---
// Analyzes recent workouts to generate a dynamic, personalized message.
Future<Response> _getDashboardHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = int.tryParse(req.url.queryParameters['user_id'] ?? '1') ?? 1;

    // 1. Calculate the Average RPE (Intensity) from the last 3 workouts
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

    // 2. Find a "Lagging Muscle" (a muscle group where the weekly goal hasn't been met)
    var goals = await conn.query('SELECT * FROM Goals WHERE user_id = ?', [userId]);
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
        currentSets = double.parse(progressQuery.first['total'].toString()).toInt();
      }

      // If they haven't reached their target, mark this muscle as lagging and break the loop
      if (currentSets < target) {
        laggingMuscle = muscle;
        break;
      }
    }

    // 3. Generate the actual string recommendation based on the collected data
    String recommendation = "";
    if (avgRpe >= 8.0) {
      // They are training too hard -> Suggest recovery
      recommendation =
          "Attention! You have had very intense workouts recently (average RPE: ${avgRpe.toStringAsFixed(1)}/10). We recommend a day of active recovery, stretching, or yoga today!";
    } else if (laggingMuscle.isNotEmpty) {
      // They are missing goals -> Suggest working out the lagging muscle
      recommendation =
          "You feel good (RPE: ${avgRpe.toStringAsFixed(1)}/10). Today would be ideal for doing a workout for '$laggingMuscle' to reach your weekly set goal!";
    } else {
      // Everything is perfect
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

// ==========================================
//   TRACKING HANDLERS (Nutrition, Hydration, Meditation)
//   These are standard CRUD endpoints.
// ==========================================

// --- SAVE NUTRITION LOG (POST) ---
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
      [userId, mealName, calories, proteins, carbs, fats, DateTime.parse(date).toUtc()],
    );

    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    print("Error saving nutrition: $e");
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- GET NUTRITION LOGS (GET) ---
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
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- SAVE NUTRITION GOAL (POST) ---
Future<Response> _saveNutritionGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final goal = data['daily_calorie_goal'] ?? 2400;

    var existing = await conn.query('SELECT id FROM NutritionGoals WHERE user_id = ?', [userId]);

    if (existing.isNotEmpty) {
      await conn.query('UPDATE NutritionGoals SET daily_calorie_goal = ? WHERE user_id = ?', [goal, userId]);
    } else {
      await conn.query('INSERT INTO NutritionGoals (user_id, daily_calorie_goal) VALUES (?, ?)', [userId, goal]);
    }

    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    print("Error saving nutrition goal: $e");
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- GET NUTRITION GOAL (GET) ---
Future<Response> _getNutritionGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';

    var result = await conn.query('SELECT daily_calorie_goal FROM NutritionGoals WHERE user_id = ?', [userId]);

    int goal = 2400; // Default fallback goal
    if (result.isNotEmpty) {
      goal = int.parse(result.first['daily_calorie_goal'].toString());
    }

    return Response.ok(
      json.encode({'daily_calorie_goal': goal}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print("Error getting nutrition goal: $e");
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- SAVE HYDRATION LOG (POST) ---
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
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- GET HYDRATION LOGS (GET) ---
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
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- SAVE HYDRATION GOAL (POST) ---
Future<Response> _saveHydrationGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final goal = data['daily_water_goal'] ?? 2500;

    var existing = await conn.query('SELECT id FROM HydrationGoals WHERE user_id = ?', [userId]);

    if (existing.isNotEmpty) {
      await conn.query('UPDATE HydrationGoals SET daily_water_goal = ? WHERE user_id = ?', [goal, userId]);
    } else {
      await conn.query('INSERT INTO HydrationGoals (user_id, daily_water_goal) VALUES (?, ?)', [userId, goal]);
    }
    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    print("Error saving hydration goal: $e");
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- GET HYDRATION GOAL (GET) ---
Future<Response> _getHydrationGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';

    var result = await conn.query('SELECT daily_water_goal FROM HydrationGoals WHERE user_id = ?', [userId]);

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
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- SAVE MEDITATION LOG (POST) ---
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
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- GET MEDITATION LOGS (GET) ---
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
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- SAVE MEDITATION GOAL (POST) ---
Future<Response> _saveMeditationGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final goal = data['daily_minutes_goal'] ?? 30;

    var existing = await conn.query('SELECT id FROM MeditationGoals WHERE user_id = ?', [userId]);

    if (existing.isNotEmpty) {
      await conn.query('UPDATE MeditationGoals SET daily_minutes_goal = ? WHERE user_id = ?', [goal, userId]);
    } else {
      await conn.query('INSERT INTO MeditationGoals (user_id, daily_minutes_goal) VALUES (?, ?)', [userId, goal]);
    }
    return Response.ok(json.encode({'status': 'success'}));
  } catch (e) {
    print("Error saving meditation goal: $e");
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}

// --- GET MEDITATION GOAL (GET) ---
Future<Response> _getMeditationGoalHandler(Request req) async {
  try {
    final conn = await Database.connect();
    final userId = req.url.queryParameters['user_id'] ?? '1';

    var result = await conn.query('SELECT daily_minutes_goal FROM MeditationGoals WHERE user_id = ?', [userId]);

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
    return Response.internalServerError(body: json.encode({'error': e.toString()}));
  }
}
