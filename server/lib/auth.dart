import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:bcrypt/bcrypt.dart';
import 'db.dart';

const jwtSecret = 'local-secret';

// Authentication middleware
Middleware authMiddleware() {
  return (Handler inner) {
    return (Request req) async {
      final auth = req.headers['authorization'];
      if (auth == null || !auth.startsWith('Bearer ')) {
        return Response.forbidden('Missing token');
      }

      try {
        final token = auth.substring(7);
        final jwt = JWT.verify(token, SecretKey(jwtSecret));
        return inner(
          req.change(
            context: {
              'uid': jwt.payload['id'],
              'admin': jwt.payload['admin'],
            },
          ),
        );
      } catch (_) {
        return Response.forbidden('Invalid token');
      }
    };
  };
}

// Register user
Future<Response> register(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final username = body['username'];
  final password = body['password'];
  final dob = body['dob'];

  if (username == null || password == null || dob == null) {
    return Response(400, body: 'Missing fields');
  }

  final hash = BCrypt.hashpw(password, BCrypt.gensalt());

  try {
    db.execute(
      "INSERT INTO users (username, password, dob, is_admin) VALUES (?, ?, ?, 0)",
      [username, hash, dob],
    );
    return Response.ok('Registered');
  } catch (_) {
    return Response(409, body: 'Username already exists');
  }
}

// Login user
Future<Response> login(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final result = db.select("SELECT * FROM users WHERE username=?", [body['username']]);

  if (result.isEmpty || !BCrypt.checkpw(body['password'], result.first['password'])) {
    return Response(403, body: 'Invalid credentials');
  }

  final jwt = JWT({'id': result.first['id'], 'admin': result.first['is_admin'] == 1});
  return Response.ok(jsonEncode({'token': jwt.sign(SecretKey(jwtSecret))}));
}
