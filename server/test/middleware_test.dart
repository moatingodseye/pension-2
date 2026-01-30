import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:full_pension_server/middleware/auth.dart';
import 'package:full_pension_server/middleware/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

void main() {
  group('Auth Middleware Tests', () {
    late Middleware middleware;
    late Handler testHandler;

    setUp(() {
      middleware = authMiddleware();
      testHandler = (Request req) {
        // Return the context values to verify they were set
        return Response.ok('uid: ${req.context['uid']}, admin: ${req.context['admin']}');
      };
    });

    test('allows OPTIONS request without token', () async {
      final req = Request('OPTIONS', Uri.parse('http://localhost/test'));
      final handler = middleware(testHandler);
      final res = await handler(req);
      expect(res.statusCode, 200);
    });

    test('rejects request without authorization header', () async {
      final req = Request('GET', Uri.parse('http://localhost/test'));
      final handler = middleware(testHandler);
      final res = await handler(req);
      expect(res.statusCode, 403);
    });

    test('rejects request with invalid authorization format', () async {
      final req = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Basic invalid'},
      );
      final handler = middleware(testHandler);
      final res = await handler(req);
      expect(res.statusCode, 403);
    });

    test('rejects request with invalid token', () async {
      final req = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Bearer invalid.token.here'},
      );
      final handler = middleware(testHandler);
      final res = await handler(req);
      expect(res.statusCode, 403);
    });

    test('accepts request with valid token and sets context', () async {
      // Create a valid JWT using the same secret as the middleware
      final jwt = JWT({'id': 1, 'admin': true});
      final token = jwt.sign(SecretKey(jwtSecret));

      final req = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Bearer $token'},
      );
      final handler = middleware(testHandler);
      final res = await handler(req);
      expect(res.statusCode, 200);

      final body = await res.readAsString();
      expect(body, contains('uid: 1'));
      expect(body, contains('admin: true'));
    });

    test('sets admin false for non-admin user', () async {
      final jwt = JWT({'id': 2, 'admin': false});
      final token = jwt.sign(SecretKey(jwtSecret));

      final req = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Bearer $token'},
      );
      final handler = middleware(testHandler);
      final res = await handler(req);
      expect(res.statusCode, 200);

      final body = await res.readAsString();
      expect(body, contains('uid: 2'));
      expect(body, contains('admin: false'));
    });
  });

  group('API Key Middleware Tests', () {
    const validApiKey = 'test-api-key-12345';
    late Handler testHandler;

    setUp(() {
      testHandler = (Request req) => Response.ok('success');
    });

    test('rejects request without Authorization header', () async {
      final middleware = apiKeyMiddleware(validApiKey);
      final req = Request('POST', Uri.parse('http://localhost/backup'));
      final res = await middleware(testHandler)(req);
      expect(res.statusCode, 403);
    });

    test('rejects request with invalid API key', () async {
      final middleware = apiKeyMiddleware(validApiKey);
      final req = Request(
        'POST',
        Uri.parse('http://localhost/backup'),
        headers: {'Authorization': 'Bearer wrong-key'},
      );
      final res = await middleware(testHandler)(req);
      expect(res.statusCode, 403);
    });

    test('accepts request with valid API key', () async {
      final middleware = apiKeyMiddleware(validApiKey);
      final req = Request(
        'POST',
        Uri.parse('http://localhost/backup'),
        headers: {'Authorization': 'Bearer $validApiKey'},
      );
      final res = await middleware(testHandler)(req);
      expect(res.statusCode, 200);
      expect(await res.readAsString(), 'success');
    });

    test('rejects request with wrong authorization format', () async {
      final middleware = apiKeyMiddleware(validApiKey);
      final req = Request(
        'POST',
        Uri.parse('http://localhost/backup'),
        headers: {'Authorization': 'Basic invalid'},
      );
      final res = await middleware(testHandler)(req);
      expect(res.statusCode, 403);
    });
  });
}
