import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:sqlite3/sqlite3.dart';
import 'db.dart';
import 'access.dart';

class User extends Access {
  User(super.db);

  // Create a user
  Future<Response> insert(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final username = body['username']?.toString();
//    final userId = req.context['uid'];

    if (body['username'] == null || body['password'] == null || body['dob'] == null) {
      return fail('Invalid, missing fields');
    }

    final hash = BCrypt.hashpw(body['password'].toString(), BCrypt.gensalt());

    final result = db.select(
      'SELECT id FROM user WHERE username = ?', [username],
    );

    if (result.isEmpty) {
      try {
        db.execute(
          '''INSERT INTO user (username, password, dob, isadmin, islocked)
          VALUES (?, ?, ?, ?, ?)''',
          [body['username'], hash, body['dob'], body['isadmin'] ?? 0, body['islocked'] ?? 1],
        );
        return ok();
      } catch(e) {
        return error(e.toString());
      }
    } else {
      return fail('Duplicate user!');
    }
  }

  // Get a list of all users
  Future<Response> select(Request req) async {
    final rows = db.select("SELECT id, username, isadmin, islocked FROM user");
    final users = rows.map((r) => {
      'id': r['id'],
      'username': r['username'],
      'isadmin': r['isadmin'],
      'islocked': r['islocked'],
    }).toList();

    return Response.ok(jsonEncode({'data': users}));
  }

  /// Update user details
  Future<Response> update(Request req, String id) async {
    final Database db = pension.getDb();
    // Convert the user ID to an integer
    final userId = int.tryParse(id);
    
    if (userId == null) {
      return fail('Invalid user ID');
    }

    // Read and parse the request body
    final body = jsonDecode(await req.readAsString());

    final String? username = body['username'];
    final String? dob = body['dob'];
    final String? password = body['password'];
    final bool isAdmin = body['isadmin'] == 1;
    final bool isislocked = body['islocked'] == 1;

    // If essential fields are missing, return an error
    if (username == null || dob == null) {
      return fail('Invalid, Missing fields');
    }

    try {
      // Check if the user exists (select query)
      final result = db.select(
        'SELECT id FROM user WHERE id = ?', [userId],
      );

      if (result.isEmpty) {
        return fail('No such user');
      }

      // Prepare the SQL query for updating user details
      final List<dynamic> params = [
        username,
        dob,
        isAdmin ? 1 : 0, // Convert bool to int (1 for true, 0 for false)
        isislocked ? 1 : 0,
        userId
      ];

      String sql = "UPDATE user SET username = ?, dob = ?, isadmin = ?, islocked = ? WHERE id = ?";

      // If a password is provided, hash it and include it in the update query
      if (password != null && password.isNotEmpty) {
        final hash = BCrypt.hashpw(password, BCrypt.gensalt());
        sql = "UPDATE user SET username = ?, dob = ?, password = ?, isadmin = ?, islocked = ? WHERE id = ?";
        params.insert(2, hash); // Insert password hash in the correct position
      }

      // Execute the update query
      db.execute(sql, params);

      // Return a success message
      return ok();
    } catch (e) {
      // Catch any errors and return a failure response
      return fail('Failed to update user: ${e.toString()}');
    }
  }

  // Get full user details by ID
  Future<Response> selectOne(Request req, String id) async {
    final Database db = pension.getDb();
    final userId = int.tryParse(id);

    if (userId == null) {
      return fail('Invalid user id');
    }

    try {
      // Fetch user details using db.select (ensure your db object is correctly initialized)
      final result = db.select(
        'SELECT id, username, dob, isadmin, islocked FROM user WHERE id = ?', 
        [userId]
      );

      if (result.isEmpty) {
        return fail('No such user');
      }

      final user = result.first;

      // Return user data as a JSON response
      return Response.ok(jsonEncode({
        'id': user['id'],
        'username': user['username'],
        'dob': user['dob'],
        'isadmin': user['isadmin'],
        'islocked': user['islocked'],
      }));
    } catch (e) {
      return fail('Error retrieving user details: ${e.toString()}');
    }
  }
}
