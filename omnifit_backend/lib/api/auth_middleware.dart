import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:omnifit_backend/services/auth_service.dart';

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final path = request.url.path;

      // Bypass authentication check for:
      // 1. Root / health-check route (empty path or '/')
      // 2. Auth routes: login and register
      // 3. Non-api routes (so that invalid routes like '/foobar' can bypass auth and throw a proper 404)
      if (!path.startsWith('api/') || 
          path == 'api/auth/login' || 
          path == 'api/auth/register') {
        return innerHandler(request);
      }

      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(
          401,
          body: json.encode({'error': 'Unauthorized. Missing or invalid Authorization header.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = authHeader.substring(7); // Extract token after 'Bearer '
      final userId = AuthService.verifyToken(token);

      if (userId == null) {
        return Response(
          401,
          body: json.encode({'error': 'Unauthorized. Invalid or expired token.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Attach verified userId to the shelf request context dynamically!
      final updatedRequest = request.change(context: {'userId': userId});
      return innerHandler(updatedRequest);
    };
  };
}
