import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:omnifit_backend/api/routes.dart';
import 'package:omnifit_backend/api/auth_middleware.dart';

void main(List<String> args) async {
  // --- Router Configuration ---
  // Mount our central API router which holds all restructured endpoints.
  final router = getApiRouter();

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
      .addMiddleware(authMiddleware()) // SECURE ALL API PATHS WITH JWT
      .addHandler(router.call);

  // --- Start Server ---
  final server = await serve(pipeline, ip, port);
  print(
    '🔥 The OmniFit Server is ONLINE at http://${server.address.host}:${server.port}',
  );
}
