import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('pension.db');
  
  print('=== Users in database ===');
  final result = db.select('SELECT id, username, dob, isadmin, islocked FROM user');
  
  for (final row in result) {
    print('ID: ${row['id']}, Username: ${row['username']}, DOB: ${row['dob']}, Admin: ${row['isadmin']}, Locked: ${row['islocked']}');
  }
  
  print('\nTotal users: ${result.length}');
  
  db.dispose();
}
