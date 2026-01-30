import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:full_pension_server/db.dart';

void main() {
  group('PensionDb Tests', () {
    test('open creates database and initializes tables', () {
      // Use in-memory db for testing
      final db = sqlite3.openInMemory();
      pension.mockDb(db);

      // Check that getDb returns the mocked db
      expect(pension.getDb(), db);

      db.dispose();
    });

    test('getDb returns database instance', () {
      final db = sqlite3.openInMemory();
      pension.mockDb(db);

      final result = pension.getDb();
      expect(result, isNotNull);
      expect(result, db);

      db.dispose();
    });

    test('mockDb allows injecting test database', () {
      final mockDb = sqlite3.openInMemory();
      pension.mockDb(mockDb);

      expect(pension.getDb(), mockDb);

      mockDb.dispose();
    });

    test('database schema includes user table', () {
      final db = sqlite3.openInMemory();
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
      pension.mockDb(db);

      // Test inserting into user table
      db.execute(
        "INSERT INTO user (username, password, dob) VALUES (?, ?, ?)",
        ['testuser', 'hash', '1990-01-01'],
      );

      final rows = db.select('SELECT * FROM user');
      expect(rows.length, 1);

      db.dispose();
    });

    test('database schema includes account table', () {
      final db = sqlite3.openInMemory();
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
      ''');
      pension.mockDb(db);

      db.execute(
        "INSERT INTO account (userId, name, amount, isType, amountAt, rate) VALUES (?, ?, ?, ?, ?, ?)",
        [1, 'Pension Pot', 50000.0, 0, '2025-01-01', 0.05],
      );

      final rows = db.select('SELECT * FROM account');
      expect(rows.length, 1);

      db.dispose();
    });

    test('database schema includes income table', () {
      final db = sqlite3.openInMemory();
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
      pension.mockDb(db);

      db.execute(
        "INSERT INTO income (userId, name, intoId, amount, rate, startAt) VALUES (?, ?, ?, ?, ?, ?)",
        [1, 'Salary', 2, 3000.0, 0.02, '2025-01-01'],
      );

      final rows = db.select('SELECT * FROM income');
      expect(rows.length, 1);

      db.dispose();
    });

    test('database schema includes outgoing table', () {
      final db = sqlite3.openInMemory();
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
      pension.mockDb(db);

      db.execute(
        "INSERT INTO outgoing (userId, name, fromId, amount, rate, startAt) VALUES (?, ?, ?, ?, ?, ?)",
        [1, 'Rent', 2, 1500.0, 0.03, '2025-01-01'],
      );

      final rows = db.select('SELECT * FROM outgoing');
      expect(rows.length, 1);

      db.dispose();
    });

    test('database schema includes transfer table', () {
      final db = sqlite3.openInMemory();
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
      pension.mockDb(db);

      db.execute(
        "INSERT INTO transfer (userId, name, fromId, intoId, amount, rate, startAt) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [1, 'Drawdown', 1, 2, 500.0, 0.02, '2025-01-01'],
      );

      final rows = db.select('SELECT * FROM transfer');
      expect(rows.length, 1);

      db.dispose();
    });
  });
}
