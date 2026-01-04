import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:sqlite3/sqlite3.dart';
import 'db.dart';

// Get a list of all users (Admin only)
Future<Response> getUsers(Request req) async {
  final Database db = pension.getDb();
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
  final Database db = pension.getDb();
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
  final Database db = pension.getDb();
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
  final Database db = pension.getDb();
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

/// Update user details
Future<Response> updateUser(Request req, String id) async {
  final Database db = pension.getDb();
  if (req.context['admin'] != true) {
    return Response(403, body: 'Admin only');
  }

  // Convert the user ID to an integer
  final userId = int.tryParse(id);
  
  if (userId == null) {
    return Response(400, body: jsonEncode({'success': false, 'error': 'Invalid user ID'}));
  }

  // Read and parse the request body
  final body = jsonDecode(await req.readAsString());

  final String? username = body['username'];
  final String? dob = body['dob'];
  final String? password = body['password'];
  final bool? isAdmin = body['is_admin'] == 1;
  final bool? isLocked = body['locked'] == 1;

  // If essential fields are missing, return an error
  if (username == null || dob == null || isAdmin == null || isLocked == null) {
    return Response(400, body: jsonEncode({'success': false, 'error': 'Missing fields'}));
  }

  try {
    // Check if the user exists (select query)
    final result = await db.select(
      'SELECT id FROM users WHERE id = ?',
      [userId],
    );

    if (result.isEmpty) {
      return Response(404, body: jsonEncode({'success': false, 'error': 'User not found'}));
    }

    // Prepare the SQL query for updating user details
    final List<dynamic> params = [
      username,
      dob,
      isAdmin ? 1 : 0, // Convert bool to int (1 for true, 0 for false)
      isLocked ? 1 : 0,
      userId
    ];

    String sql = "UPDATE users SET username = ?, dob = ?, is_admin = ?, locked = ? WHERE id = ?";

    // If a password is provided, hash it and include it in the update query
    if (password != null && password.isNotEmpty) {
      final hash = BCrypt.hashpw(password, BCrypt.gensalt());
      sql = "UPDATE users SET username = ?, dob = ?, password = ?, is_admin = ?, locked = ? WHERE id = ?";
      params.insert(2, hash); // Insert password hash in the correct position
    }

    // Execute the update query
    db.execute(sql, params);

    // Return a success message
    return Response.ok(jsonEncode({'success': true, 'message': 'User updated successfully'}));
  } catch (e) {
    // Catch any errors and return a failure response
    return Response(500, body: jsonEncode({'success': false, 'error': 'Failed to update user: ${e.toString()}'}));
  }
}

// Get full user details by ID
Future<Response> getUser(Request req, String id) async {
  final Database db = pension.getDb();
  if (req.context['admin'] != true) {
    return Response(403, body: 'Admin only');
  }

  final userId = int.tryParse(id);

  if (userId == null) {
    return Response(400, body: jsonEncode({'success': false, 'error': 'Invalid user ID'}));
  }

  try {
    // Fetch user details using db.select (ensure your db object is correctly initialized)
    final result = await db.select(
      'SELECT id, username, dob, is_admin, locked FROM users WHERE id = ?', 
      [userId]
    );

    if (result.isEmpty) {
      return Response(404, body: jsonEncode({'success': false, 'error': 'User not found'}));
    }

    final user = result.first;

    // Return user data as a JSON response
    return Response.ok(jsonEncode({
      'id': user['id'],
      'username': user['username'],
      'dob': user['dob'],
      'is_admin': user['is_admin'],
      'locked': user['locked'],
    }));
  } catch (e) {
    return Response(500, body: jsonEncode({'success': false, 'error': 'Error retrieving user details: ${e.toString()}'}));
  }
}

