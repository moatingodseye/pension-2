import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

const jwtSecret = 'local-secret';

Middleware authMiddleware({bool adminOnly = false}) {
  return (Handler inner) {
    return (Request req) async {
      final auth = req.headers['authorization'];
      if (auth == null || !auth.startsWith('Bearer ')) {
        return Response.forbidden('Missing token');
      }

      try {
        final jwt = JWT.verify(auth.substring(7), SecretKey(jwtSecret));

        if (adminOnly && jwt.payload['admin'] != true) {
          return Response.forbidden('Admin only');
        }

        return inner(req.change(context: jwt.payload));
      } catch (_) {
        return Response.forbidden('Invalid token');
      }
    };
  };
}
