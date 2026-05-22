import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ApiService {
  static final String _baseUrl = ApiConstants.baseUrl;
  static String? _token;

  /// Initialize the API Service by loading any existing token from storage.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  /// Check if a user is currently authenticated.
  static bool get isAuthenticated => _token != null;

  /// Get the currently stored token.
  static String? get token => _token;

  /// Save a new token after successful login or registration.
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Remove token from storage and memory (Logout).
  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Combines authorization headers with user headers.
  static Map<String, String> _buildHeaders(Map<String, String>? userHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (userHeaders != null) {
      headers.addAll(userHeaders);
    }
    return headers;
  }

  /// Performs a secure GET request.
  static Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.get(url, headers: _buildHeaders(headers));
  }

  /// Performs a secure POST request.
  static Future<http.Response> post(String endpoint, {Map<String, String>? headers, Object? body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.post(
      url,
      headers: _buildHeaders(headers),
      body: body is Map || body is List ? json.encode(body) : body,
    );
  }

  /// Performs a secure DELETE request.
  static Future<http.Response> delete(String endpoint, {Map<String, String>? headers, Object? body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.delete(
      url,
      headers: _buildHeaders(headers),
      body: body is Map || body is List ? json.encode(body) : body,
    );
  }

  /// Performs user login.
  static Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    try {
      final url = Uri.parse('$_baseUrl/api/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token']);
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error. Make sure the backend is running.'};
    }
  }

  /// Performs user registration.
  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final url = Uri.parse('$_baseUrl/api/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token']);
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error. Make sure the backend is running.'};
    }
  }
}
