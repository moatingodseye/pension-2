import 'package:sqlite3/sqlite3.dart';

final db = sqlite3.open('pension.db');

void initDb() {
  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE,
      password TEXT,
      dob TEXT,
      is_admin INTEGER,
      locked INTEGER DEFAULT 0
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS refresh_tokens (
      token TEXT,
      user_id INTEGER
    )
  ''');
}
