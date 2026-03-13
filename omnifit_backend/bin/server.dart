import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// 1. Configurăm rutele (Endpoint-urile)
final router = Router()
  ..get('/', _rootHandler)
  ..post('/api/auth/login', _loginHandler); // Aici e endpoint-ul pentru Persoana 1

// 2. Răspuns de test pentru a vedea că serverul merge
Response _rootHandler(Request req) {
  return Response.ok('Serverul OmniFit este UP! Poti continua cu hackathon-ul.\n');
}

// 3. Logica de Login (Mock-up)
Future<Response> _loginHandler(Request req) async {
  try {
    // Citim ce trimite aplicația de mobil
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final email = data['email'];
    final password = data['password'];

    // Simulăm verificarea (mai târziu vei folosi DAO-ul de la Persoana 4 aici)
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

// 4. Pornirea serverului
void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // Adăugăm un "middleware" care ne afișează în consolă fiecare cerere primită
  final pipeline = Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final server = await serve(pipeline, ip, port);
  print('🔥 Backend-ul OmniFit rulează pe http://${server.address.host}:${server.port}');
}