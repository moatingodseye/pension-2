import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

class Access {
  final Database db;

  Access(this.db);

  Response fail(String message) {
    return Response.badRequest(
      body: jsonEncode({
        'success': false,
        'message': message,
      }),
      headers: {'Content-Type': 'application/json'},);
  }

  Response forbidden(String message) {
    return Response.forbidden(jsonEncode({'success': false, 'message': message}),
      headers: {'Content-Type': 'application/json'},);
  }

  Response unauthorised(String message) {
    return Response.unauthorized(jsonEncode({
        'success': false,
        'message': message,
      }),
      headers: {'Content-Type': 'application/json'},);
  }

  Response ok({String? message}) {
    return Response.ok(
      jsonEncode({
        'success': true,
        if (message != null) 'message': message,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response error(String message) {
    return Response.internalServerError(body:jsonEncode({
        'success': false,
        'message': message,
      }),
      headers: {'Content-Type': 'application/json'},);
  }
}