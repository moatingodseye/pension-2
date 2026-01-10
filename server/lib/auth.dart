import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:bcrypt/bcrypt.dart';
import 'db.dart';
import 'access.dart';
import 'user.dart';
import 'middleware/auth.dart';

class Authentication extends Access {
  Authentication(Database db) : super(db);

  // Register user
  Future<Response> register(Request req) async {
    final user = new User(db);
    return await user.insert(req);
  }

  // Login user
  Future<Response> login(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final username = body['username']?.toString();
    final password = body['password']?.toString();

    if (username == null || password == null) {
      return fail('Invalid, missing fields');
    }

    try {
      // Query to fetch user details based on username
      final result = await db.select(
        'SELECT id, password, isadmin, islocked FROM user WHERE username = ?',
        [username],
      );

      if (result.isEmpty) {
        return fail('No such user');
      }

      final user = result.first;

      // Check if the account is locked
      if (user['locked'] == 1) {
        return forbidden('Acount locked');
      }

      // Check if the password matches
      final isPasswordCorrect = BCrypt.checkpw(password, user['password']);
      if (!isPasswordCorrect) {
        return unauthorised('Invalid');
      }

      final jwt = JWT({'id': user['id'], 'admin': user['isadmin'] == 1});
      return Response.ok(jsonEncode({'token': jwt.sign(SecretKey(jwtSecret)), 'isAdmin': user['isadmin']}));
    } catch (e) {
      return error('${e.toString()}');
    }
  }
}