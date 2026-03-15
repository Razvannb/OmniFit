import 'package:omnifit_backend/db/database.dart';

void main() async {
  print('⏳ Încercare de conectare la baza de date...');
  
  try {
    final conn = await Database.connect();
    print('✅ SUCCES! Serverul Dart s-a conectat la MySQL cu succes!');
    
    // Testăm dacă găsește baza de date și tabelele
    var result = await conn.query('SHOW TABLES;');
    print('Tabele găsite în baza de date omnifit:');
    for (var row in result) {
      print(' - ${row[0]}');
    }
    
    await conn.close();
  } catch (e) {
    print('❌ EROARE DE CONEXIUNE:');
    print(e.toString());
  }
}