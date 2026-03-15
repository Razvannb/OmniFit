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
    ..delete('/api/delete-workout', _deleteWorkoutHandler) // RUTA NOUĂ PENTRU DELETE
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
  print(
    '🔥 Serverul OmniFit este ONLINE pe http://${server.address.host}:${server.port}',
  );
}

// --- HANDLER ROOT (Health Check) ---
Response _rootHandler(Request req) {
  return Response.ok(
<<<<<<< Updated upstream
    json.encode({'status': 'online', 'message': 'OmniFit API rulează corect'}),
=======
    json.encode({'status': 'online'}),
>>>>>>> Stashed changes
    headers: {'Content-Type': 'application/json'},
  );
}

// --- HANDLER PLACEHOLDER (Pentru rutele neimplementate încă) ---
Future<Response> _placeholderHandler(Request req) async {
  return Response.ok(
<<<<<<< Updated upstream
    json.encode({'status': 'coming_soon', 'message': 'Acest endpoint va fi implementat în curând.'}),
=======
    json.encode({'status': 'coming_soon'}),
>>>>>>> Stashed changes
    headers: {'Content-Type': 'application/json'},
  );
}

// --- HANDLER SALVARE & EDITARE ANTRENAMENT (POST) ---
Future<Response> _saveWorkoutHandler(Request req) async {
<<<<<<< Updated upstream
=======
  final conn = await Database.connect();
>>>>>>> Stashed changes
  try {
    final conn = await Database.connect(); 
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final incomingId = data['id']; // Poate fi null (nou) sau un ID existent (editare)
    final userId = data['user_id'] ?? 1;
<<<<<<< Updated upstream
    final workoutName = data['workoutName'] ?? 'Fără nume';
    final date = data['date'] ?? DateTime.now().toIso8601String();
=======
    final workoutName = (data['workoutName'] ?? 'Fără nume')
        .toString()
        .replaceAll("'", "''");

    String dateStr;
    try {
      dateStr =
          '${DateTime.parse(data['date']).toIso8601String().split('T')[0]} ${DateTime.parse(data['date']).toIso8601String().split('T')[1].substring(0, 8)}';
    } catch (_) {
      dateStr =
          '${DateTime.now().toIso8601String().split('T')[0]} ${DateTime.now().toIso8601String().split('T')[1].substring(0, 8)}';
    }

>>>>>>> Stashed changes
    final rpe = data['rpe'] ?? 5.0;
    final List<dynamic>? exercises = data['exercises'];

    int currentWorkoutId;

<<<<<<< Updated upstream
    // 1. Verificăm dacă este EDITARE sau ADĂUGARE NOUĂ
    // Dacă ID-ul există și nu este unul generat local de Flutter (care conține #)
    if (incomingId != null && !incomingId.toString().contains('#')) {
      // ESTE EDITARE! Facem UPDATE
      currentWorkoutId = int.parse(incomingId.toString());
      await conn.query(
        'UPDATE Workouts SET name = ?, rpe = ?, date_created = ? WHERE id = ?',
        [workoutName, rpe, DateTime.parse(date), currentWorkoutId]
      );
      
      // Ștergem exercițiile vechi din baza de date pentru a le pune pe cele noi
      await conn.query('DELETE FROM Sets WHERE workoutID = ?', [currentWorkoutId]);
      
    } else {
      // ESTE ADĂUGARE NOUĂ! Facem INSERT
      var result = await conn.query(
        'INSERT INTO Workouts (user_id, name, rpe, date_created) VALUES (?, ?, ?, ?)',
        [userId, workoutName, rpe, DateTime.parse(date)]
      );
      currentWorkoutId = result.insertId!; 
    }

    // 2. Inserăm Exercițiile noi (se rulează mereu ca să avem seturile actualizate)
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
            ex['recoveryExercise']
          ]
        );
=======
    // TRANZACȚIE: Forțează baza de date și driverul să respecte ordinea!
    await conn.transaction((ctx) async {
      // 1. Inserăm Antrenamentul
      var result = await ctx.query(
        "INSERT INTO Workouts (user_id, name, rpe, date_created) VALUES ($userId, '$workoutName', $rpe, '$dateStr')",
      );

      newWorkoutId = result.insertId!;

      // 2. Inserăm Exercițiile
      if (exercises != null && exercises.isNotEmpty) {
        List<String> valuesList = [];

        for (var ex in exercises) {
          String exName = (ex['exerciseName'] ?? '').toString().replaceAll(
            "'",
            "''",
          );
          String mGroup = (ex['muscleGroup'] ?? '').toString().replaceAll(
            "'",
            "''",
          );
          int setsCount = ex['sets'] ?? 0;
          String reps = (ex['reps'] ?? '').toString().replaceAll("'", "''");
          int recBetween = ex['recoveryBetweenSets'] ?? 60;
          int recEx = ex['recoveryExercise'] ?? 30;

          valuesList.add(
            "($newWorkoutId, '$exName', '$mGroup', $setsCount, '$reps', $recBetween, $recEx)",
          );
        }

        String bulkInsertQuery =
            "INSERT INTO Sets (workoutID, exerciseName, muscleGroup, setsCount, reps, recoveryBetweenSets, recoveryExercise) VALUES ${valuesList.join(", ")}";

        await ctx.query(bulkInsertQuery); // Aici se va aștepta corect
>>>>>>> Stashed changes
      }
    }

<<<<<<< Updated upstream
    // Returnăm succesul și id-ul antrenamentului
    return Response.ok(json.encode({
      'status': 'success', 
      'workout_id': currentWorkoutId
    }), headers: {'Content-Type': 'application/json'});

=======
    return Response.ok(
      json.encode({'status': 'success', 'workout_id': newWorkoutId}),
      headers: {'Content-Type': 'application/json'},
    );
>>>>>>> Stashed changes
  } catch (e) {
    print("Eroare la salvare: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
<<<<<<< Updated upstream
      headers: {'Content-Type': 'application/json'}
=======
      headers: {'Content-Type': 'application/json'},
>>>>>>> Stashed changes
    );
  }
  // Am scos `finally { await conn.close(); }` pentru a preveni eroarea "Socket closed"
}

// --- HANDLER EXTRAGERE ANTRENAMENTE (GET) ---
Future<Response> _getWorkoutHandler(Request req) async {
<<<<<<< Updated upstream
  try {
    final conn = await Database.connect();
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
=======
  final conn =
      await Database.connect(); // Deschidem o conexiune NOUĂ pentru acest request
  try {
    final userIdParam = req.url.queryParameters['user_id'] ?? '1';
    int parsedUserId = int.tryParse(userIdParam) ?? 1;

    var workoutsResult = await conn.query('''
      SELECT 
        id, 
        name, 
        CAST(rpe AS CHAR) as rpe_str, 
        CAST(date_created AS CHAR) as date_str 
      FROM Workouts 
      WHERE user_id = $parsedUserId 
      ORDER BY date_created DESC
      ''');

    if (workoutsResult.isEmpty) {
      return Response.ok(
        json.encode([]),
        headers: {'Content-Type': 'application/json'},
      );
    }

    List<int> workoutIds = [];
    Map<int, Map<String, dynamic>> workoutsMap = {};

    for (var w in workoutsResult) {
      int wId = w['id'];
      workoutIds.add(wId);

      String rawDate = w['date_str']?.toString() ?? DateTime.now().toString();
      double parsedRpe =
          double.tryParse(w['rpe_str']?.toString() ?? '5.0') ?? 5.0;

      workoutsMap[wId] = {
        "id": wId,
        "workoutName": w['name'],
        "date": rawDate,
        "rpe": parsedRpe,
        "globalRestTime": 60,
        "exercises": <Map<String, dynamic>>[],
      };
    }

    String idsPlaceholders = workoutIds.join(',');

    var setsResult = await conn.query(
      'SELECT * FROM Sets WHERE workoutID IN ($idsPlaceholders)',
    );

    for (var s in setsResult) {
      int wId = s['workoutID'];

      if (workoutsMap.containsKey(wId)) {
        var exercisesList =
            workoutsMap[wId]!['exercises'] as List<Map<String, dynamic>>;

        if (exercisesList.isEmpty) {
          workoutsMap[wId]!['globalRestTime'] = s['recoveryBetweenSets'] ?? 60;
>>>>>>> Stashed changes
        }

        exercisesJson.add({
          "exerciseName": s['exerciseName'],
          "muscleGroup": s['muscleGroup'],
          "sets": s['setsCount'],
          "reps": s['reps'], // Baza de date returnează string-ul "10,12,10"
          "recoveryBetweenSets": s['recoveryBetweenSets'],
          "recoveryExercise": s['recoveryExercise'],
        });
      }

      // 3. Construim obiectul pentru Frontend
      finalWorkouts.add({
        "id": workoutId, // ID-ul real din DB
        "workoutName": w['name'],
        "date": (w['date_created'] as DateTime).toIso8601String(),
        "rpe": w['rpe'],
        "globalRestTime": workoutGlobalRest,
        "exercises": exercisesJson // Punem array-ul de exerciții aici
      });
    }

<<<<<<< Updated upstream
=======
    List<Map<String, dynamic>> finalWorkouts = workoutsMap.values.toList();

>>>>>>> Stashed changes
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

// --- HANDLER ȘTERGERE ANTRENAMENT (DELETE) ---
Future<Response> _deleteWorkoutHandler(Request req) async {
  try {
    final workoutId = req.url.queryParameters['id'];
    if (workoutId == null) {
      return Response.badRequest(
        body: json.encode({'error': 'Lipsește ID-ul antrenamentului.'}),
        headers: {'Content-Type': 'application/json'}
      );
    }

    final conn = await Database.connect();
    
    // Ștergem Antrenamentul
    // (Exercițiile din tabela Sets se vor șterge automat datorită ON DELETE CASCADE setat in SQL)
    await conn.query('DELETE FROM Workouts WHERE id = ?', [workoutId]);
    
    return Response.ok(
      json.encode({'status': 'deleted', 'message': 'Antrenamentul a fost șters!'}),
      headers: {'Content-Type': 'application/json'}
    );
  } catch (e) {
    print("Eroare la ștergere: $e");
    return Response.internalServerError(
      body: json.encode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'}
    );
  }
}
