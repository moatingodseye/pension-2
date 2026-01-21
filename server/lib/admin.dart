import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'access.dart';

class Admin extends Access {
  Admin(super.db);

  // Lock a user (Admin only)
  Future<Response> lock(Request req, String id) async {
    if (req.context['admin'] != true) {
      return unauthorised('Admin only');
    }

    final userId = int.tryParse(id);
    if (userId == null) return fail('Invalid user ID');

    try {
      db.execute("UPDATE user SET islocked=1 WHERE id=?", [userId]);
      return ok();
    } catch (e) {
      return fail(e.toString());
    }
  }

  // Unlock a user (Admin only)
  Future<Response> unlock(Request req, String id) async {
    if (req.context['admin'] != true) {
      return unauthorised('Admin only');
    }

    final userId = int.tryParse(id);
    if (userId == null) return fail('Invalid user ID');

    try {
      db.execute("UPDATE user SET islocked=0 WHERE id=?", [userId]);
      return ok();
    } catch (e) {
      return fail(e.toString());
    }
  }

  // Reset user password (Admin only)
  Future<Response> reset(Request req, String id) async {
    if (req.context['admin'] != true) {
      return unauthorised('Admin only');
    }

    final userId = int.tryParse(id);
    if (userId == null) return fail('Invalid user ID');

    // Parse JSON
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await req.readAsString());
    } catch (e) {
      return fail('Invalid JSON format');
    }

    final newPassword = body['new_password'];
    if (newPassword == null || newPassword.isEmpty) {
      return fail('Password is required');
    }

    try {
      final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      db.execute("UPDATE user SET password=? WHERE id=?", [hash, userId]);
      return ok();
    } catch (e) {
      return fail(e.toString());
    }
  }
}
