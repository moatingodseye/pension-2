import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:bcrypt/bcrypt.dart';

const jwtSecret = 'local-secret-key-that-you-cannot-guess-smiley';

// Authentication middleware
Middleware authMiddleware() {
  return (Handler inner) {
    return (Request req) async {
      final auth = req.headers['authorization'];
      if (auth == null || !auth.startsWith('Bearer ')) {
        return Response.forbidden('Missing token');
      }

      try {
        final token = auth.substring(7);
        final jwt = JWT.verify(token, SecretKey(jwtSecret));
        return inner(
          req.change(
            context: {
              'uid': jwt.payload['id'],
              'admin': jwt.payload['admin'],
            },
          ),
        );
      } catch (_) {
        return Response.forbidden('Invalid token');
      }
    };
  };
}