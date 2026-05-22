import 'package:omnifit_backend/db/database.dart';
import 'package:omnifit_backend/models/user.dart';

class UserRepository {
  Future<int> createUser(User user) async {
    final conn = await Database.connect();
    final result = await conn.query(
      'INSERT INTO Users (username, email, password) VALUES (?, ?, ?)',
      [user.username, user.email, user.password],
    );
    return result.insertId!;
  }

  Future<User?> getUserByEmail(String email) async {
    final conn = await Database.connect();
    final result = await conn.query('SELECT * FROM Users WHERE email = ?', [email]);
    if (result.isEmpty) return null;
    final row = result.first;
    return User(
      id: row['id'],
      username: row['username'].toString(),
      email: row['email'].toString(),
      password: row['password'].toString(),
    );
  }

  Future<User?> getUserByUsername(String username) async {
    final conn = await Database.connect();
    final result = await conn.query('SELECT * FROM Users WHERE username = ?', [username]);
    if (result.isEmpty) return null;
    final row = result.first;
    return User(
      id: row['id'],
      username: row['username'].toString(),
      email: row['email'].toString(),
      password: row['password'].toString(),
    );
  }
}
