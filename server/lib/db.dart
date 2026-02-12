import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

final pension = PensionDb();

class PensionDb {
  Database? _db;

  void open() {
    _db = sqlite3.open('pension.db');
    _initDb();
  } 

  void close() {
    _db?.dispose();
    _db = null;
  }

  Database getDb() {
    if (_db == null) {
      open();
    }
    return _db!;
  }

  void mockDb(Database db) {
    _db = db;
  }

  void _initDb() {  
    Database db = getDb();
    db.execute('''
      CREATE TABLE IF NOT EXISTS user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        dob TEXT,
        isAdmin INTEGER DEFAULT 0,
        isLocked INTEGER DEFAULT 0
      )
    ''');

    // accounts, one for each pension pot, one for current account, one for savings account etc
    db.execute('''
      CREATE TABLE IF NOT EXISTS account (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        isType INTEGER, 
        name TEXT,
        amount REAL,
        amountAt TEXT, 
        rate REAL
      )
    '''); // istype=0 pension, 2=current

    // income, money coming in from an external source (not pension)
    db.execute('''
      CREATE TABLE IF NOT EXISTS income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        name TEXT,
        intoId INTEGER,
        amount REAL,
        rate REAL,
        startAt TEXT,
        endAt TEXT
      )
    ''');

    // outgoing, spending, should be coming from current or savings.
    db.execute('''
      CREATE TABLE IF NOT EXISTS outgoing (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        name TEXT,
        fromId INTEGER,
        amount REAL,
        rate REAL,
        startAt TEXT,
        endAt TEXT
      )
    '''); 

    // drawdown, transfer from one account to another on regular basis
    db.execute('''
      CREATE TABLE IF NOT EXISTS transfer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        name TEXT,
        fromId INTEGER,
        intoId INTEGER,
        amount REAL,
        rate REAL,
        startAt TEXT,
        endAt TEXT
      )
    '''); 

    migrate();

    final admin = db.select("SELECT * FROM user WHERE username='admin'");
    if (admin.isEmpty) {
      final hash = BCrypt.hashpw('admin', BCrypt.gensalt());
      db.execute(
        "INSERT INTO user (username, password, dob, isadmin, islocked) VALUES (?, ?, ?, ?, ?)",
        ['admin', hash, '1970-01-01',1,0],
      );
    }
  }

/*   // Migration to add the "name" column to pension_pots if it doesn't exist
  void _addPensionPotNameColumn() {
    Database db = getDb();
    try {
      final result = db.select("PRAGMA table_info(pension_pots);");
      final columns = result.map((row) => row['name'] as String).toList();

      if (!columns.contains('name')) {
        db.execute("ALTER TABLE pension_pots ADD COLUMN name TEXT;");
        logTo("Column 'name' added to pension_pots table.");
      }
    } catch (e) {
      logTo("Migration failed: $e");
    }
  }

  void _addPensionPotToDrawdowns() {
    Database db = getDb();
    try {
      final result = db.select("PRAGMA table_info(drawdowns);");
      final columns = result.map((row) => row['name'] as String).toList();

      if (!columns.contains('pension_pot_id')) {
        db.execute("ALTER TABLE drawdowns ADD COLUMN pension_pot_id INTEGER;");
        logTo("Column 'pension_pot_id' added to drawdowns table.");
      }
    } catch (e) {
      logTo("Migration failed: $e");
    }
  } */

  void migrate() {
/*     _addPensionPotNameColumn();
    _addPensionPotToDrawdowns();
 */  
  }
}
