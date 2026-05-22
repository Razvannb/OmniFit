import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:omnifit_backend/models/user.dart';
import 'package:omnifit_backend/repositories/user_repository.dart';

class AuthService {
  final UserRepository _userRepository = UserRepository();
  
  // Custom secret key for signing JSON Web Tokens
  static const String _jwtSecret = 'omnifit_super_secret_key_12345';

  Future<String> register(String username, String email, String password) async {
    // 1. Check if user already exists by email
    final existingUser = await _userRepository.getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('User with this email already exists.');
    }

    // Check if user already exists by username
    final existingUsername = await _userRepository.getUserByUsername(username);
    if (existingUsername != null) {
      throw Exception('User with this username already exists.');
    }

    // 2. Hash user password securely using BCrypt
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    // 3. Create user in the database
    final user = User(username: username, email: email, password: hashedPassword);
    final userId = await _userRepository.createUser(user);

    // 4. Generate and sign a new JWT token
    return _generateToken(userId);
  }

  Future<String> login(String usernameOrEmail, String password) async {
    // 1. Fetch user by email or username
    User? user;
    if (usernameOrEmail.contains('@')) {
      user = await _userRepository.getUserByEmail(usernameOrEmail);
    } else {
      user = await _userRepository.getUserByUsername(usernameOrEmail);
    }

    if (user == null) {
      throw Exception('Invalid username/email or password.');
    }

    // 2. Verify password with stored BCrypt hash
    if (!BCrypt.checkpw(password, user.password)) {
      throw Exception('Invalid username/email or password.');
    }

    // 3. Generate and sign a new JWT token
    return _generateToken(user.id!);
  }

  String _generateToken(int userId) {
    final jwt = JWT({
      'userId': userId,
      'exp': DateTime.now().add(Duration(days: 7)).millisecondsSinceEpoch ~/ 1000,
    });
    return jwt.sign(SecretKey(_jwtSecret));
  }

  static int? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;
      return payload['userId'] as int?;
    } catch (e) {
      return null;
    }
  }
}
