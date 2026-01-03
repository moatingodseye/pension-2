import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

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
    CREATE TABLE IF NOT EXISTS pension_pots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      name TEXT,
      amount REAL,
      date TEXT,
      interest_rate REAL
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS drawdowns (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      amount REAL,
      start_date TEXT,
      end_date TEXT,
      interest_rate REAL
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS state_pensions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      start_age INTEGER,
      amount REAL,
      interest_rate REAL
    )
  ''');

  _addPensionPotNameColumn();
  _addPensionPotToDrawdowns();

  final admin = db.select("SELECT * FROM users WHERE username='admin'");
  if (admin.isEmpty) {
    final hash = BCrypt.hashpw('admin', BCrypt.gensalt());
    db.execute(
      "INSERT INTO users (username, password, dob, is_admin) VALUES (?, ?, ?, 1)",
      ['admin', hash, '1970-01-01'],
    );
  }
}

// Migration to add the "name" column to pension_pots if it doesn't exist
void _addPensionPotNameColumn() {
  try {
    final result = db.select("PRAGMA table_info(pension_pots);");
    final columns = result.map((row) => row['name'] as String).toList();

    if (!columns.contains('name')) {
      db.execute("ALTER TABLE pension_pots ADD COLUMN name TEXT;");
      print("Column 'name' added to pension_pots table.");
    }
  } catch (e) {
    print("Migration failed: $e");
  }
}

void _addPensionPotToDrawdowns() {
  try {
    final result = db.select("PRAGMA table_info(drawdowns);");
    final columns = result.map((row) => row['name'] as String).toList();

    if (!columns.contains('pension_pot_id')) {
      db.execute("ALTER TABLE drawdowns ADD COLUMN pension_pot_id INTEGER;");
      print("Column 'pension_pot_id' added to drawdowns table.");
    }
  } catch (e) {
    print("Migration failed: $e");
  }
}

