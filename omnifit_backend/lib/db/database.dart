import 'package:mysql1/mysql1.dart';

class Database {
  static Future<MySqlConnection> connect() async {
    final settings = ConnectionSettings(
      host: '127.0.0.1', // 🔥 SECRETUL PENTRU MAC: 127.0.0.1 în loc de localhost
      port: 3306,
      user: 'root',
      password: '', // Lasă gol dacă nu ai parolă în DBngin/MAMP
      db: 'omnifit',
    );

    return await MySqlConnection.connect(settings);
  }
}