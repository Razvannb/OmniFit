import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Importurile din proiectul tău
import 'package:omnifit_backend/db/database.dart';

void main(List<String> args) async {
  final router = Router()
    ..get('/', _rootHandler)
    ..post('/api/save-workout', _saveWorkoutHandler)
    ..get('/api/get-workout', _getWorkoutHandler)
    ..post('/api/auth/login', _placeholderHandler)
    ..post('/api/hydration', _placeholderHandler)
    ..post('/api/nutrition', _placeholderHandler)
    ..post('/api/goals', _placeholderHandler);

  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await serve(pipeline, ip, port);
  print('🔥 Serverul OmniFit este ONLINE pe http://${server.address.host}:${server.port}');
}

Response _rootHandler(Request req) {
  return Response.ok(json.encode({'status': 'online'}), headers: {'Content-Type': 'application/json'});
}

Future<Response> _placeholderHandler(Request req) async {
  return Response.ok(json.encode({'status': 'coming_soon'}), headers: {'Content-Type': 'application/json'});
}

// --- HANDLER SALVARE ANTRENAMENT (POST) ---
Future<Response> _saveWorkoutHandler(Request req) async {
  final conn = await Database.connect(); 
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final userId = data['user_id'] ?? 1;
    final workoutName = (data['workoutName'] ?? 'Fără nume').toString().replaceAll("'", "''");
    
    String dateStr;
    try {
      dateStr = DateTime.parse(data['date']).toIso8601String().split('T')[0] + ' ' + DateTime.parse(data['date']).toIso8601String().split('T')[1].substring(0,8);
    } catch (_) {
      dateStr = DateTime.now().toIso8601String().split('T')[0] + ' ' + DateTime.now().toIso8601String().split('T')[1].substring(0,8);
    }
    
    final rpe = data['rpe'] ?? 5.0;
    final List<dynamic>? exercises = data['exercises'];

    int newWorkoutId = 0;

    // TRANZACȚIE: Forțează baza de date și driverul să respecte ordinea!
    await conn.transaction((ctx) async {
      // 1. Inserăm Antrenamentul
      var result = await ctx.query(
        "INSERT INTO Workouts (user_id, name, rpe, date_created) VALUES ($userId, '$workoutName', $rpe, '$dateStr')"
      );
      
      newWorkoutId = result.insertId!; 

      // 2. Inserăm Exercițiile
      if (exercises != null && exercises.isNotEmpty) {
        List<String> valuesList = [];

        for (var ex in exercises) {
          String exName = (ex['exerciseName'] ?? '').toString().replaceAll("'", "''");
          String mGroup = (ex['muscleGroup'] ?? '').toString().replaceAll("'", "''");
          int setsCount = ex['sets'] ?? 0;
          String reps = (ex['reps'] ?? '').toString().replaceAll("'", "''");
          int recBetween = ex['recoveryBetweenSets'] ?? 60;
          int recEx = ex['recoveryExercise'] ?? 30;

          valuesList.add("($newWorkoutId, '$exName', '$mGroup', $setsCount, '$reps', $recBetween, $recEx)");
        }

        String bulkInsertQuery = "INSERT INTO Sets (workoutID, exerciseName, muscleGroup, setsCount, reps, recoveryBetweenSets, recoveryExercise) VALUES " + valuesList.join(", ");

        await ctx.query(bulkInsertQuery); // Aici se va aștepta corect
      }
    }); // Sfârșitul tranzacției

    return Response.ok(
      json.encode({'status': 'success', 'workout_id': newWorkoutId}), 
      headers: {'Content-Type': 'application/json'}
    );

  } catch (e) {
    print("Eroare la salvare: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}), 
      headers: {'Content-Type': 'application/json'}
    );
  } finally {
    await conn.close(); // Închidem conexiunea
  }
}

// --- HANDLER EXTRAGERE ANTRENAMENTE (GET) ---
Future<Response> _getWorkoutHandler(Request req) async {
  final conn = await Database.connect(); // Deschidem o conexiune NOUĂ pentru acest request
  try {
    final userIdParam = req.url.queryParameters['user_id'] ?? '1';
    int parsedUserId = int.tryParse(userIdParam) ?? 1; 

    var workoutsResult = await conn.query(
      '''
      SELECT 
        id, 
        name, 
        CAST(rpe AS CHAR) as rpe_str, 
        CAST(date_created AS CHAR) as date_str 
      FROM Workouts 
      WHERE user_id = $parsedUserId 
      ORDER BY date_created DESC
      '''
    );

    if (workoutsResult.isEmpty) {
      return Response.ok(json.encode([]), headers: {'Content-Type': 'application/json'});
    }

    List<int> workoutIds = [];
    Map<int, Map<String, dynamic>> workoutsMap = {};

    for (var w in workoutsResult) {
      int wId = w['id'];
      workoutIds.add(wId);
      
      String rawDate = w['date_str']?.toString() ?? DateTime.now().toString();
      double parsedRpe = double.tryParse(w['rpe_str']?.toString() ?? '5.0') ?? 5.0;

      workoutsMap[wId] = {
        "id": wId,
        "workoutName": w['name'],
        "date": rawDate,
        "rpe": parsedRpe,
        "globalRestTime": 60, 
        "exercises": <Map<String, dynamic>>[]
      };
    }

    String idsPlaceholders = workoutIds.join(',');
    
    var setsResult = await conn.query(
      'SELECT * FROM Sets WHERE workoutID IN ($idsPlaceholders)'
    );

    for (var s in setsResult) {
      int wId = s['workoutID'];
      
      if (workoutsMap.containsKey(wId)) {
        var exercisesList = workoutsMap[wId]!['exercises'] as List<Map<String, dynamic>>;
        
        if (exercisesList.isEmpty) {
          workoutsMap[wId]!['globalRestTime'] = s['recoveryBetweenSets'] ?? 60;
        }

        exercisesList.add({
          "exerciseName": s['exerciseName']?.toString() ?? '',
          "muscleGroup": s['muscleGroup']?.toString() ?? '',
          "sets": s['setsCount'] ?? 0,
          "reps": s['reps']?.toString() ?? '',
          "recoveryBetweenSets": s['recoveryBetweenSets'] ?? 60,
          "recoveryExercise": s['recoveryExercise'] ?? 30,
        });
      }
    }

    List<Map<String, dynamic>> finalWorkouts = workoutsMap.values.toList();
    
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
    await conn.close(); // Închidem curat conexiunea după ce terminăm
  }
}