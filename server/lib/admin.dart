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

    db.execute("UPDATE user SET islocked=1 WHERE id=?", [id]);
    return ok();
  }

  // Unlock a user (Admin only)
  Future<Response> unlock(Request req, String id) async {
    if (req.context['admin'] != true) {
      return unauthorised('Admin only');
    }

    db.execute("UPDATE user SET islocked=0 WHERE id=?", [id]);
    return ok();
  }

  // Reset user password (Admin only)
  Future<Response> reset(Request req, String id) async {
    if (req.context['admin'] != true) {
      return unauthorised('Admin only');
    }

    final body = jsonDecode(await req.readAsString());
    final newPassword = body['new_password'];

    final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    db.execute("UPDATE user SET password=? WHERE id=?", [hash, id]);

    return ok();
  }
}
