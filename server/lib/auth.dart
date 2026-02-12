import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:bcrypt/bcrypt.dart';
import 'access.dart';
import 'user.dart';
import 'package:shared/models/user.dart' as models;
import 'middleware/auth.dart';

class Authentication extends Access {
  Authentication(super.db);

  // Register user
  Future<Response> register(Request req) async {
    final user = UserApi(db);
    return await user.insert(req);
  }

  // Login user
  Future<Response> login(Request req) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await req.readAsString());
    } catch (e) {
      return fail('Invalid JSON format');
    }

    final username = body['username']?.toString();
    final password = body['password']?.toString();

    if (username == null || password == null) {
      return fail('Invalid, missing fields');
    }

    try {
      // Query to fetch user details based on username
      final result = db.select(
        'SELECT id, username, password, isAdmin, isLocked, dob FROM user WHERE username = ?',
        [username],
      );

      if (result.isEmpty) {
        return fail('No such user');
      }

      // Convert to User model
      final user = models.User.fromDb(result.first);

      // Check if the account is locked
      if (user.isLocked) {
        return forbidden('Account locked');
      }

      // Check if the password matches
      // Note: User model fromDb might not have password set if we were selecting strict fields, 
      // but here we expressly selected it. 
      // The shared User model maps 'password' from the DB result if available.
      // However, looking at User.fromDb in the shared model, it expects 'password' key to map it?
      // Actually checking User.dart, fromDb calls fromJson. 
      // fromJson expects 'password'. db.select returns lowercase column names usually?
      // Let's rely on standard map key access if User model is strict on keys.
      // But wait, the shared model `fromDb` maps keys. 
      
      final dbPassword = result.first['password'] as String?;

      if (dbPassword == null) {
          return fail('User data corruption (no password set)');
      }

      final isPasswordCorrect = BCrypt.checkpw(password, dbPassword);
      if (!isPasswordCorrect) {
        return unauthorised('Invalid credentials');
      }

      final jwt = JWT({'id': user.id, 'admin': user.isAdmin});
      
      return Response.ok(jsonEncode({
        'token': jwt.sign(SecretKey(jwtSecret)), 
        'isAdmin': user.isAdmin,
        'id': user.id,
        'dob': user.dob?.toIso8601String()
      }));
    } catch (e) {
      return error(e.toString());
    }
  }
}