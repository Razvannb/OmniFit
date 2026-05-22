import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:omnifit_backend/services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<Response> login(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);

      final usernameOrEmail = data['usernameOrEmail'] ?? data['username'] ?? data['email'];
      final password = data['password'];

      if (usernameOrEmail == null || password == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Username/Email and Password are required.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = await _authService.login(usernameOrEmail, password);

      return Response.ok(
        json.encode({
          'status': 'success',
          'token': token,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Login error: $e");
      return Response.forbidden(
        json.encode({'error': e.toString().replaceAll('Exception: ', '')}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> register(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);

      final username = data['username'];
      final email = data['email'];
      final password = data['password'];

      if (username == null || email == null || password == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Username, email, and password are required.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = await _authService.register(username, email, password);

      return Response.ok(
        json.encode({
          'status': 'success',
          'token': token,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print("Register error: $e");
      return Response.badRequest(
        body: json.encode({'error': e.toString().replaceAll('Exception: ', '')}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
