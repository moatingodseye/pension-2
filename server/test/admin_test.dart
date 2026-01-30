import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:full_pension_server/db.dart';
import 'package:full_pension_server/admin.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';

void main() {
  group('Admin Tests', () {
    late Database db;
    late Admin admin;

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
      // Insert test user
      db.execute("INSERT INTO user (id, username, password, dob, islocked) VALUES (1, 'testuser', 'hash', '1990-01-01', 0)");
      pension.mockDb(db);
      admin = Admin(db);
    });

    tearDown(() {
      db.dispose();
    });

    group('lock', () {
      test('locks user when admin', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/lock/1'),
          context: {'admin': true, 'uid': 99},
        );

        final res = await admin.lock(req, '1');
        expect(res.statusCode, 200);

        final row = db.select('SELECT islocked FROM user WHERE id = 1').first;
        expect(row['islocked'], 1);
      });

      test('rejects non-admin', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/lock/1'),
          context: {'admin': false, 'uid': 1},
        );

        final res = await admin.lock(req, '1');
        expect(res.statusCode, 401);
      });

      test('rejects invalid user id', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/lock/abc'),
          context: {'admin': true, 'uid': 99},
        );

        final res = await admin.lock(req, 'abc');
        expect(res.statusCode, 400);
      });
    });

    group('unlock', () {
      setUp(() {
        db.execute("UPDATE user SET islocked = 1 WHERE id = 1");
      });

      test('unlocks user when admin', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/unlock/1'),
          context: {'admin': true, 'uid': 99},
        );

        final res = await admin.unlock(req, '1');
        expect(res.statusCode, 200);

        final row = db.select('SELECT islocked FROM user WHERE id = 1').first;
        expect(row['islocked'], 0);
      });

      test('rejects non-admin', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/unlock/1'),
          context: {'admin': false, 'uid': 1},
        );

        final res = await admin.unlock(req, '1');
        expect(res.statusCode, 401);
      });

      test('rejects invalid user id', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/unlock/abc'),
          context: {'admin': true, 'uid': 99},
        );

        final res = await admin.unlock(req, 'abc');
        expect(res.statusCode, 400);
      });
    });

    group('reset', () {
      test('resets password when admin', () async {
        final originalHash = db.select('SELECT password FROM user WHERE id = 1').first['password'];

        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/reset/1'),
          context: {'admin': true, 'uid': 99},
          body: jsonEncode({'new_password': 'newpassword123'}),
        );

        final res = await admin.reset(req, '1');
        expect(res.statusCode, 200);

        final newHash = db.select('SELECT password FROM user WHERE id = 1').first['password'];
        expect(newHash, isNot(originalHash));
      });

      test('rejects non-admin', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/reset/1'),
          context: {'admin': false, 'uid': 1},
          body: jsonEncode({'new_password': 'newpassword123'}),
        );

        final res = await admin.reset(req, '1');
        expect(res.statusCode, 401);
      });

      test('rejects missing password', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/reset/1'),
          context: {'admin': true, 'uid': 99},
          body: jsonEncode({}),
        );

        final res = await admin.reset(req, '1');
        expect(res.statusCode, 400);
      });

      test('rejects empty password', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/reset/1'),
          context: {'admin': true, 'uid': 99},
          body: jsonEncode({'new_password': ''}),
        );

        final res = await admin.reset(req, '1');
        expect(res.statusCode, 400);
      });

      test('rejects invalid JSON', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/reset/1'),
          context: {'admin': true, 'uid': 99},
          body: 'not json',
        );

        final res = await admin.reset(req, '1');
        expect(res.statusCode, 400);
      });

      test('rejects invalid user id', () async {
        final req = Request(
          'POST',
          Uri.parse('http://localhost/admin/reset/abc'),
          context: {'admin': true, 'uid': 99},
          body: jsonEncode({'new_password': 'newpassword123'}),
        );

        final res = await admin.reset(req, 'abc');
        expect(res.statusCode, 400);
      });
    });
  });
}
