import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'db.dart';

// Get a list of all users (Admin only)
Future<Response> getUsers(Request req) async {
  if (req.context['admin'] != true) {
    return Response(403, body: 'Admin only');
  }

  final rows = db.select("SELECT id, username, is_admin, locked FROM users");
  final users = rows.map((r) => {
    'id': r['id'],
    'username': r['username'],
    'is_admin': r['is_admin'],
    'locked': r['locked'],
  }).toList();

  return Response.ok(jsonEncode({'data': users}));
}

// Lock a user (Admin only)
Future<Response> lockUser(Request req) async {
  if (req.context['admin'] != true) {
    return Response(403, body: 'Admin only');
  }

  final body = jsonDecode(await req.readAsString());
  final userId = body['user_id'];

  db.execute("UPDATE users SET locked=1 WHERE id=?", [userId]);
  return Response.ok(jsonEncode({'message': 'User locked'}));
}

// Unlock a user (Admin only)
Future<Response> unlockUser(Request req) async {
  if (req.context['admin'] != true) {
    return Response(403, body: 'Admin only');
  }

  final body = jsonDecode(await req.readAsString());
  final userId = body['user_id'];

  db.execute("UPDATE users SET locked=0 WHERE id=?", [userId]);
  return Response.ok(jsonEncode({'message': 'User unlocked'}));
}

// Reset user password (Admin only)
Future<Response> resetPassword(Request req) async {
  if (req.context['admin'] != true) {
    return Response(403, body: 'Admin only');
  }

  final body = jsonDecode(await req.readAsString());
  final userId = body['user_id'];
  final newPassword = body['new_password'];

  final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
  db.execute("UPDATE users SET password=? WHERE id=?", [hash, userId]);

  return Response.ok(jsonEncode({'message': 'Password reset successfully'}));
}
