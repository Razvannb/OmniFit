import 'package:mysql1/mysql1.dart';

class Database {
  static Future<MySqlConnection> connect() async {
    final settings = ConnectionSettings(
      host: 'localhost', // Serverul este pe laptopul tău
      port: 3306, // Portul standard pentru MySQL
      user: 'root', // Aici pui userul tău din DBngin (de obicei este 'root')
      password:
          '', // Aici pui parola (dacă nu ai pus nicio parolă la DBngin, lasă gol așa: '')
      db: 'omnifit', // Numele bazei tale de date pe care ai creat-o cu CREATE DATABASE
    );

    return await MySqlConnection.connect(settings);
  }
}
