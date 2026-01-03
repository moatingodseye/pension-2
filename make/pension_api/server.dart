import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'lib/db.dart';
import 'lib/validation.dart';

void main() async {
  initDb();
  final app = Router();

  app.post('/register', (req) async {
    final body = jsonDecode(await req.readAsString());
    requireFields(body, ['username','password','dob']);

    if (!strongPassword(body['password'])) {
      return Response.badRequest(body: 'Weak password');
    }

    final hash = BCrypt.hashpw(body['password'], BCrypt.gensalt());
    db.execute(
      "INSERT INTO users (username,password,dob,is_admin) VALUES (?,?,?,0)",
      [body['username'], hash, body['dob']]
    );

    return Response.ok('Registered');
  });

  app.post('/login', (req) async {
    final body = jsonDecode(await req.readAsString());
    final r = db.select("SELECT * FROM users WHERE username=?", [body['username']]);
    if (r.isEmpty || !BCrypt.checkpw(body['password'], r.first['password'])) {
      return Response.forbidden('Invalid');
    }

    final jwt = JWT({
      'id': r.first['id'],
      'admin': r.first['is_admin'] == 1,
      'exp': DateTime.now().add(Duration(hours:1)).millisecondsSinceEpoch ~/ 1000
    });

    return Response.ok(jsonEncode({'token': jwt.sign(SecretKey('local-secret'))}),
      headers: {'content-type':'application/json'});
  });

  await serve(app, InternetAddress.anyIPv4, 8080);
}
