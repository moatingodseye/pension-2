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
        isadmin INTEGER DEFAULT 0,
        islocked INTEGER DEFAULT 0
      )
    ''');

    // accounts, one for each pension pot, one for current account, one for savings account etc
    db.execute('''
      CREATE TABLE IF NOT EXISTS account (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER,
        istype INTEGER, 
        name TEXT,
        amount REAL,
        age TEXT,
        amountat TEXT,
        rate REAL
      )
    '''); // istype=0 pension, 2=current

    // income, money coming in from an external source (not pension)
    db.execute('''
      CREATE TABLE IF NOT EXISTS income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER,
        name TEXT,
        intoid INTEGER,
        amount REAL,
        startat TEXT,
        endat TEXT,
        rate REAL
      )
    ''');

    // outgoing, spending, should be coming from current or savings.
    db.execute('''
      CREATE TABLE IF NOT EXISTS outgoing (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER,
        name TEXT,
        fromid INTEGER,
        amount REAL,
        startat TEXT,
        endat TEXT,
        rate REAL
      )
    '''); 

    // drawdown, transfer from one account to another on regular basis
    db.execute('''
      CREATE TABLE IF NOT EXISTS transfer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER,
        name TEXT,
        fromid INTEGER,
        intoid INTEGER,
        amount REAL,
        startat TEXT,
        endat TEXT,
        rate REAL
      )
    '''); 

/*     db.execute('''
      CREATE TABLE IF NOT EXISTS state_pensions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        start_age INTEGER,
        amount REAL,
        interest_rate REAL
      )
    '''); */

    migrate();

    final admin = db.select("SELECT * FROM user WHERE username='admin'");
    if (admin.isEmpty) {
      final hash = BCrypt.hashpw('admin', BCrypt.gensalt());
      db.execute(
        "INSERT INTO user (username, password, dob, isadmin, islocked) VALUES (?, ?, ?, 1, 0)",
        ['admin', hash, '1970-01-01'],
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
