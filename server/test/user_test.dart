import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:full_pension_server/db.dart';
import 'package:full_pension_server/user.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';

void main() {
  group('UserApi Tests', () {
    late Database db;
    late UserApi userApi;

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
      userApi = UserApi(db);
    });

    tearDown(() {
      db.dispose();
    });

    group('insert', () {
      test('creates new user', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/user'),
          body: jsonEncode({
            'username': 'newuser',
            'password': 'password123',
            'dob': '1990-05-15',
          }),
        );

        final res = await userApi.insert(req);
        expect(res.statusCode, 200);

        final rows = db.select('SELECT * FROM user WHERE username = ?', ['newuser']);
        expect(rows.length, 1);
      });

      test('rejects duplicate username', () async {
        db.execute("INSERT INTO user (username, password, dob) VALUES ('existing', 'hash', '1990-01-01')");

        final req = Request(
          'POST',
          Uri.parse('http://localhost/user'),
          body: jsonEncode({
            'username': 'existing',
            'password': 'password123',
            'dob': '1990-01-01',
          }),
        );

        final res = await userApi.insert(req);
        expect(res.statusCode, 400);
      });
    });

    group('select', () {
      test('returns list of users', () async {
        db.execute("INSERT INTO user (username, password, dob, isadmin) VALUES ('user1', 'hash', '1990-01-01', 0)");
        db.execute("INSERT INTO user (username, password, dob, isadmin) VALUES ('user2', 'hash', '1985-05-15', 1)");

        final req = Request('GET', Uri.parse('http://localhost/user'));
        final res = await userApi.select(req);
        expect(res.statusCode, 200);

        final body = jsonDecode(await res.readAsString());
        expect(body['data'], hasLength(2));
      });

      test('returns empty list when no users', () async {
        final req = Request('GET', Uri.parse('http://localhost/user'));
        final res = await userApi.select(req);
        expect(res.statusCode, 200);

        final body = jsonDecode(await res.readAsString());
        expect(body['data'], isEmpty);
      });
    });

    group('selectOne', () {
      test('returns user by id', () async {
        db.execute("INSERT INTO user (id, username, password, dob, isadmin) VALUES (1, 'testuser', 'hash', '1990-01-01', 0)");

        final req = Request('GET', Uri.parse('http://localhost/user/1'));
        final res = await userApi.selectOne(req, '1');
        expect(res.statusCode, 200);

        final body = jsonDecode(await res.readAsString());
        expect(body['username'], 'testuser');
      });

      test('returns error for non-existent user', () async {
        final req = Request('GET', Uri.parse('http://localhost/user/999'));
        final res = await userApi.selectOne(req, '999');
        expect(res.statusCode, 400);
      });

      test('returns error for invalid id', () async {
        final req = Request('GET', Uri.parse('http://localhost/user/abc'));
        final res = await userApi.selectOne(req, 'abc');
        expect(res.statusCode, 400);
      });
    });

    group('update', () {
      test('updates user details', () async {
        db.execute("INSERT INTO user (id, username, password, dob, isadmin) VALUES (1, 'oldname', 'hash', '1990-01-01', 0)");

        final req = Request(
          'PUT',
          Uri.parse('http://localhost/user/1'),
          body: jsonEncode({
            'username': 'newname',
            'dob': '1990-01-01',
            'isadmin': false,
            'islocked': false,
          }),
        );

        final res = await userApi.update(req, '1');
        expect(res.statusCode, 200);

        final row = db.select('SELECT * FROM user WHERE id = 1').first;
        expect(row['username'], 'newname');
      });

      test('updates password when provided', () async {
        db.execute("INSERT INTO user (id, username, password, dob) VALUES (1, 'user', 'oldhash', '1990-01-01')");

        final req = Request(
          'PUT',
          Uri.parse('http://localhost/user/1'),
          body: jsonEncode({
            'username': 'user',
            'password': 'newpassword',
            'dob': '1990-01-01',
          }),
        );

        final res = await userApi.update(req, '1');
        expect(res.statusCode, 200);

        final row = db.select('SELECT password FROM user WHERE id = 1').first;
        expect(row['password'], isNot('oldhash'));
      });

      test('returns error for non-existent user', () async {
        final req = Request(
          'PUT',
          Uri.parse('http://localhost/user/999'),
          body: jsonEncode({
            'username': 'name',
            'dob': '1990-01-01',
          }),
        );

        final res = await userApi.update(req, '999');
        expect(res.statusCode, 400);
      });

      test('returns error for invalid id', () async {
        final req = Request(
          'PUT',
          Uri.parse('http://localhost/user/abc'),
          body: jsonEncode({
            'username': 'name',
            'dob': '1990-01-01',
          }),
        );

        final res = await userApi.update(req, 'abc');
        expect(res.statusCode, 400);
      });
    });
  });
}
