import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// 1. Configurăm rutele (Endpoint-urile)
final router = Router()
  ..get('/', _rootHandler)
  ..post('/api/auth/login', _loginHandler)
  ..post('/api/workouts', _createWorkoutHandler)
  ..post('/api/rpe', _logRpeHandler); // <-- RUTA PENTRU RPE ESTE ACUM AICI

// Răspuns de test
Response _rootHandler(Request req) {
  return Response.ok('Serverul OmniFit este UP! Poti continua cu hackathon-ul.\n');
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
        json.encode({
          'status': 'success', 
          'message': 'Te-ai logat cu succes!', 
          'token': 'mock_token_hackathon_123'
        }),
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

// 2. Logica ACTUALIZATĂ pentru Salvarea Antrenamentelor (F1)
Future<Response> _createWorkoutHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    // 1. Extragem datele pentru tabela `Workouts`
    final userId = data['user_id']; // Fix cum e în SQL

    // 2. Extragem lista de seturi pentru tabela `Sets`
    final List<dynamic>? sets = data['sets']; 

    if (userId == null || sets == null || sets.isEmpty) {
       return Response.badRequest(
        body: json.encode({'status': 'error', 'message': 'Date incomplete (lipseste user_id sau sets).'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // 3. Validăm că Frontend-ul trimite exact structura cerută de Persoana 4 pentru tabela `Sets`
    for (var setRecord in sets) {
      if (setRecord['exerciseName'] == null || 
          setRecord['setOrder'] == null || 
          setRecord['reps'] == null) {
        return Response.badRequest(
          body: json.encode({'status': 'error', 'message': 'Set invalid. Verifica exerciseName, setOrder si reps.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    }

    // --- PUNCT DE INTEGRARE ---
    // Când Persoana 4 finalizează Stratul de Acces la Date (DAO), aici vei conecta codul tău cu al ei:
    // int newWorkoutId = await DatabaseDAO.createWorkout(userId);
    // await DatabaseDAO.insertSets(newWorkoutId, sets);
    // --------------------------

    return Response.ok(
      json.encode({
        'status': 'success', 
        'message': 'Antrenamentul si seturile sunt pregatite pentru baza de date!',
        'setsProcessed': sets.length
      }),
      headers: {'Content-Type': 'application/json'},
    );

  } catch (e) {
    return Response.internalServerError(body: json.encode({'error': 'Eroare de procesare: $e'}));
  }
}

// 3. Logica pentru Evaluarea Efortului (F3 - RPE)
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

    // Validăm ca valoarea RPE să fie exact cum cere baza de date (între 1 și 10)
    if (rpeValue < 1 || rpeValue > 10) {
       return Response.badRequest(
        body: json.encode({'status': 'error', 'message': 'RPE trebuie sa fie o nota de la 1 la 10.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // --- PUNCT DE INTEGRARE ---
    // Când Persoana 4 e gata, aici vei scrie: await DatabaseDAO.insertRpe(workoutId, rpeValue);
    // --------------------------

    return Response.ok(
      json.encode({'status': 'success', 'message': 'RPE-ul a fost pregatit pentru salvare!'}),
      headers: {'Content-Type': 'application/json'},
    );

  } catch (e) {
    return Response.internalServerError(body: json.encode({'error': 'Eroare de procesare: $e'}));
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