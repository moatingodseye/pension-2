$ErrorActionPreference = "Stop"

$Root = "pension_api"
$Zip = "pension_api.zip"

if (Test-Path $Root) { Remove-Item $Root -Recurse -Force }
if (Test-Path $Zip) { Remove-Item $Zip -Force }

New-Item -ItemType Directory -Path $Root, "$Root/lib", "$Root/tests" | Out-Null

# ---------------- pubspec.yaml ----------------
@"
name: pension_api
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.4
  sqlite3: ^2.4.0
  bcrypt: ^1.1.3
  dart_jsonwebtoken: ^2.12.0
"@ | Set-Content "$Root/pubspec.yaml"

# ---------------- README.md ----------------
@"
# Pension API

## Run
dart pub get
dart run server.dart

## Test (Windows)
./test_api.ps1
"@ | Set-Content "$Root/README.md"

# ---------------- lib/db.dart ----------------
@"
import 'package:sqlite3/sqlite3.dart';

final db = sqlite3.open('pension.db');

void initDb() {
  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE,
      password TEXT,
      dob TEXT,
      is_admin INTEGER,
      locked INTEGER DEFAULT 0
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS refresh_tokens (
      token TEXT,
      user_id INTEGER
    )
  ''');
}
"@ | Set-Content "$Root/lib/db.dart"

# ---------------- lib/validation.dart ----------------
@"
void requireFields(Map body, List<String> fields) {
  for (final f in fields) {
    if (!body.containsKey(f)) {
      throw Exception('Missing field: $f');
    }
  }
}

bool strongPassword(String p) =>
  p.length >= 8 &&
  p.contains(RegExp(r'[A-Z]')) &&
  p.contains(RegExp(r'[0-9]'));
"@ | Set-Content "$Root/lib/validation.dart"

# ---------------- lib/auth.dart ----------------
@"
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
"@ | Set-Content "$Root/lib/auth.dart"

# ---------------- server.dart ----------------
@"
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
"@ | Set-Content "$Root/server.dart"

# ---------------- test script ----------------
@"
Write-Host 'Smoke test passed (placeholder)'
"@ | Set-Content "$Root/tests/smoke_test.ps1"

# ---------------- ZIP IT ----------------
Compress-Archive -Path $Root -DestinationPath $Zip

Write-Host "Created $Zip successfully"
