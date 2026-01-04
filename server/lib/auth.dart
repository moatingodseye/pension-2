import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
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

/* import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
 */
// Middleware to check API key in the Authorization header
Middleware apiKeyAuth(String validApiKey) {
  return (Handler handler) {
    return (Request request) async {
      final header = request.headers['Authorization'];

      if (header == null || !header.startsWith('Bearer ')) {
        return Response.forbidden('Invalid API key');
      }

      // Remove the 'Bearer ' prefix
      final apiKey = header.substring('Bearer '.length);

      if (apiKey != validApiKey) {
        return Response.forbidden('Invalid API key');
      }

      // If the API key is valid, continue with the request
      return await handler(request);
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
    return Response(
      400,
      body: jsonEncode({'success': false, 'error': 'Missing fields'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final hash = BCrypt.hashpw(password, BCrypt.gensalt());

  Database db = pension.getDb();
  try {
    // create user default to none admin and locked so anyone can register but admin has to approve
    db.execute(
      "INSERT INTO users (username, password, dob, locked, is_admin) VALUES (?, ?, ?, 1, 0)", 
      [username, hash, dob],
    );
    return Response.ok(
      jsonEncode({'success': true, 'message': 'Registered successfully'}),
      headers: {'Content-Type': 'application/json'},
    );  
  } catch (_) {
    return Response(
      409,
      body: jsonEncode({'success': false, 'error': 'Username already exists'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// Login user
Future<Response> login(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final username = body['username']?.toString();
  final password = body['password']?.toString();

  if (username == null || password == null) {
    return Response(400, body: jsonEncode({'success': false, 'error': 'Username and password are required'}));
  }

  Database db = pension.getDb();
  try {
    // Query to fetch user details based on username
    final result = await db.select(
      'SELECT id, username, password, is_admin, locked FROM users WHERE username = ?',
      [username],
    );

    if (result.isEmpty) {
      return Response(401, body: jsonEncode({'success': false, 'error': 'Invalid username or password'}));
    }

    final user = result.first;

    // Check if the account is locked
    if (user['locked'] == 1) {
      return Response(403, body: jsonEncode({'success': false, 'error': 'Account is locked'}));  // 403 Forbidden
    }

    // Check if the password matches
    final isPasswordCorrect = BCrypt.checkpw(password, user['password']);
    if (!isPasswordCorrect) {
      return Response(401, body: jsonEncode({'success': false, 'error': 'Invalid username or password'}));
    }

    final jwt = JWT({'id': user['id'], 'admin': user['is_admin'] == 1});
    return Response.ok(jsonEncode({'token': jwt.sign(SecretKey(jwtSecret)), 'isAdmin': user['is_admin']}));
  } catch (e) {
    return Response(500, body: jsonEncode({'success': false, 'error': 'Error during login: ${e.toString()}'}));
  }
}
