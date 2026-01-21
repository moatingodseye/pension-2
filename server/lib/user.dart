import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:shared/models/user.dart' as models;
import 'access.dart';

class UserApi extends Access {
  UserApi(super.db);

  // Create a user
  Future<Response> insert(Request req) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await req.readAsString());
    } catch (e) {
      return fail('Invalid JSON format');
    }

    // Parse into User model for validation
    final models.User newUser;
    try {
      newUser = models.User.fromJson(body);
    } catch (e) {
      return fail('Invalid user data: ${e.toString()}');
    }

    // Validate required fields
    if (newUser.password == null || newUser.password!.isEmpty) {
      return fail('Password is required');
    }

    // Check for duplicate username
    final result = db.select(
      'SELECT id FROM user WHERE username = ?', [newUser.username],
    );

    if (result.isNotEmpty) {
      return fail('Duplicate user!');
    }

    // Hash password
    final hash = BCrypt.hashpw(newUser.password!, BCrypt.gensalt());

    // Validate dob is present for registration
    if (newUser.dob == null) {
      return fail('Date of birth is required');
    }

    // Insert using model fields
    try {
      db.execute(
        '''INSERT INTO user (username, password, dob, isadmin, islocked)
        VALUES (?, ?, ?, ?, ?)''',
        [
          newUser.username,
          hash,
          newUser.dob!.toIso8601String().split('T')[0],
          newUser.isAdmin ? 1 : 0,
          newUser.isLocked ? 1 : 0
        ],
      );
      return ok(message:'User registered, now unlock them for usage');
    } catch(e) {
      return error(e.toString());
    }
  }

  // Get a list of all users
  Future<Response> select(Request req) async {
    final rows = db.select("SELECT id, username, isadmin, islocked FROM user");
    
    // Convert rows to User models (without dob for list view)
    final users = rows.map((r) => models.User(
      id: r['id'] as int,
      username: r['username'] as String,
      isAdmin: r['isadmin'] == 1,
      isLocked: r['islocked'] == 1,
      // dob is null for list endpoint
    )).toList();

    // Convert models to JSON
    final usersJson = users.map((u) => u.toJson()).toList();
    
    return Response.ok(jsonEncode({'data': usersJson}));
  }

  /// Update user details
  Future<Response> update(Request req, String id) async {
    final userId = int.tryParse(id);
    
    if (userId == null) {
      return fail('Invalid user ID');
    }

    // Parse request body
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await req.readAsString());
    } catch (e) {
      return fail('Invalid JSON format');
    }

    // Parse into User model
    final models.User updatedUser;
    try {
      updatedUser = models.User.fromJson(body);
    } catch (e) {
      return fail('Invalid user data: ${e.toString()}');
    }

    // Validate required fields
    if (updatedUser.dob == null) {
      return fail('Date of birth is required for update');
    }

    try {
      // Check if the user exists
      final result = db.select(
        'SELECT id FROM user WHERE id = ?', [userId],
      );

      if (result.isEmpty) {
        return fail('No such user');
      }

      // Build update query based on whether password is provided
      if (updatedUser.password != null && updatedUser.password!.isNotEmpty) {
        final hash = BCrypt.hashpw(updatedUser.password!, BCrypt.gensalt());
        db.execute(
          "UPDATE user SET username = ?, dob = ?, password = ?, isadmin = ?, islocked = ? WHERE id = ?",
          [
            updatedUser.username,
            updatedUser.dob!.toIso8601String().split('T')[0],
            hash,
            updatedUser.isAdmin ? 1 : 0,
            updatedUser.isLocked ? 1 : 0,
            userId
          ]
        );
      } else {
        db.execute(
          "UPDATE user SET username = ?, dob = ?, isadmin = ?, islocked = ? WHERE id = ?",
          [
            updatedUser.username,
            updatedUser.dob!.toIso8601String().split('T')[0],
            updatedUser.isAdmin ? 1 : 0,
            updatedUser.isLocked ? 1 : 0,
            userId
          ]
        );
      }

      return ok();
    } catch (e) {
      return fail('Failed to update user: ${e.toString()}');
    }
  }

  // Get full user details by ID
  Future<Response> selectOne(Request req, String id) async {
    final userId = int.tryParse(id);

    if (userId == null) {
      return fail('Invalid user id');
    }

    try {
      // Fetch user details
      final result = db.select(
        'SELECT id, username, dob, isadmin, islocked FROM user WHERE id = ?', 
        [userId]
      );

      if (result.isEmpty) {
        return fail('No such user');
      }

      final row = result.first;
      
      // Convert to User model
      final user = models.User(
        id: row['id'] as int,
        username: row['username'] as String,
        dob: DateTime.parse(row['dob'] as String),
        isAdmin: row['isadmin'] == 1,
        isLocked: row['islocked'] == 1,
      );

      // Return user as JSON
      return Response.ok(jsonEncode(user.toJson()));
    } catch (e) {
      return fail('Error retrieving user details: ${e.toString()}');
    }
  }
}
