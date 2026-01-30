import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:full_pension_server/db.dart';
import 'package:full_pension_server/auth.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';

void main() {
  group('Authentication Tests', () {
    late Database db;
    late Authentication auth;

    setUp(() {
      db = sqlite3.openInMemory();
      db.execute('''
        CREATE TABLE user (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE,
          password TEXT,
          dob TEXT,
          isadmin INTEGER DEFAULT 0,
          islocked INTEGER DEFAULT 0
        )
      ''');
      pension.mockDb(db);
      auth = Authentication(db);
    });

    tearDown(() {
      db.dispose();
    });

    group('register', () {
      test('registers new user successfully', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/register'),
          body: jsonEncode({
            'username': 'newuser',
            'password': 'password123',
            'dob': '1990-01-01',
          }),
        );

        final res = await auth.register(req);
        expect(res.statusCode, 200);

        final rows = db.select('SELECT * FROM user WHERE username = ?', ['newuser']);
        expect(rows.length, 1);
        expect(rows.first['username'], 'newuser');
      });

      test('rejects duplicate username', () async {
        // Insert existing user
        db.execute(
          "INSERT INTO user (username, password, dob) VALUES (?, ?, ?)",
          ['existing', 'hash', '1990-01-01'],
        );

        final req = Request(
          'POST',
          Uri.parse('http://localhost/register'),
          body: jsonEncode({
            'username': 'existing',
            'password': 'password123',
            'dob': '1990-01-01',
          }),
        );

        final res = await auth.register(req);
        expect(res.statusCode, 400);
        final body = jsonDecode(await res.readAsString());
        expect(body['success'], false);
      });

      test('rejects missing password', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/register'),
          body: jsonEncode({
            'username': 'nopassword',
            'dob': '1990-01-01',
          }),
        );

        final res = await auth.register(req);
        expect(res.statusCode, 400);
      });

      test('rejects missing dob', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/register'),
          body: jsonEncode({
            'username': 'nodob',
            'password': 'password123',
          }),
        );

        final res = await auth.register(req);
        expect(res.statusCode, 400);
      });

      test('rejects invalid JSON', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/register'),
          body: 'not valid json',
        );

        final res = await auth.register(req);
        expect(res.statusCode, 400);
      });
    });

    group('login', () {
      setUp(() {
        // Insert test user with bcrypt hash of 'password123'
        // Using pre-computed hash for test consistency
        final hash = '\$2b\$10\$YourSaltHereXXXXXXXXXXOY.UjC3w5gMCbVb7M9D5EZw6J8KjL.Ky';
        db.execute(
          "INSERT INTO user (id, username, password, dob, isadmin, islocked) VALUES (?, ?, ?, ?, ?, ?)",
          [1, 'testuser', hash, '1990-01-01', 0, 0],
        );
      });

      test('rejects non-existent user', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/login'),
          body: jsonEncode({
            'username': 'nonexistent',
            'password': 'password123',
          }),
        );

        final res = await auth.login(req);
        expect(res.statusCode, 400);
      });

      test('rejects locked user', () async {
        db.execute("UPDATE user SET islocked = 1 WHERE username = 'testuser'");

        final req = Request(
          'POST',
          Uri.parse('http://localhost/login'),
          body: jsonEncode({
            'username': 'testuser',
            'password': 'password123',
          }),
        );

        final res = await auth.login(req);
        expect(res.statusCode, 403);
      });

      test('rejects missing fields', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/login'),
          body: jsonEncode({
            'username': 'testuser',
            // missing password
          }),
        );

        final res = await auth.login(req);
        expect(res.statusCode, 400);
      });

      test('rejects invalid JSON', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/login'),
          body: 'invalid json',
        );

        final res = await auth.login(req);
        expect(res.statusCode, 400);
      });
    });
  });
}
