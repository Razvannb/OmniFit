import 'package:mysql1/mysql1.dart';
import '../models/user.dart';

// DAO (Data Access Object) responsible for handling User database operations.
class UserDao {
  final MySqlConnection _conn;

  // Constructor that requires a valid MySQL connection.
  UserDao(this._conn);

  // Registers a new user by inserting their details into the database.
  Future<void> registerUser(User user) async {
    await _conn.query(
      // Executes an INSERT query safely using parameterized inputs (?, ?, ?) to prevent SQL injection.
      'INSERT INTO Users (username, email, password) VALUES (?, ?, ?)',
      [user.username, user.email, user.password],
    );
  }

  // Retrieves a user by their email address (useful for login authentication).
  Future<User?> loginUser(String email) async {
    var result = await _conn.query(
      // Executes a SELECT query filtering by email.
      'SELECT * FROM Users WHERE email = ?',
      [email],
    );

    // If no user is found with the provided email, return null.
    if (result.isEmpty) return null;

    // Converts the first matching MySQL row into a User Dart object.
    return User.fromRow(result.first.fields);
  }

  // Updates user profile information (username, email, or password).
  // This must be a separate method within the class.
  Future<void> updateUser(User user) async {
    await _conn.query(
      // Executes an UPDATE query to modify user credentials for a record identified by its unique ID.
      'UPDATE Users SET username = ?, email = ?, password = ? WHERE id = ?',
      [user.username, user.email, user.password, user.id],
    );
  }
}
