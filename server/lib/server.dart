import 'dart:io';
import 'package:full_pension_server/monitor.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'db.dart';
import 'auth.dart';
import 'user.dart';
import 'pension.dart';
import 'drawdown.dart';
import 'state_pension.dart';
import 'simulate.dart';
import 'debuglogger.dart';
import 'backup.dart';

void main() async {
  setupClientLogging();

  // Initialize the database and run migrations
  pension.open();

  final pub = Router();
  final prot = Router();

  // Public pipeline (no auth)
  final public = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(monitor1)
      .addHandler(pub);

  // Protected pipeline (with auth)
  final protected = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(authMiddleware())
      .addMiddleware(monitor2)
      .addHandler(prot);

  final cas = Cascade().add(public).add(protected).handler;

  // --- Public routes ---
  pub
    ..post('/register', register)
    ..post('/login', login);
    
  const validApiKey = 'your-secure-api-key';

  // Add routes with API key authentication
  pub.post('/backup', apiKeyAuth(validApiKey)(backupHandler));
  pub.post('/restore', apiKeyAuth(validApiKey)(restoreHandler));


  pub.mount('/', protected);

  // --- Protected routes ---
  prot
    ..post('/pension_pots', createPensionPot)
    ..get('/pension_pots', listPensionPots)
    ..delete('/pension_pots/<id>', deletePensionPot)
    ..put('/pension_pots/<id>', updatePensionPot)

    ..post('/drawdowns', createDrawdown)
    ..get('/drawdowns', listDrawdowns)
    ..delete('/drawdowns/<id>', deleteDrawdown)
    ..put('/drawdowns/<id>', updateDrawdown)

    ..post('/state_pension', createStatePension)
    ..get('/state_pension', listStatePensions)
    ..put('/state_pension/<id>',updateStatePension)

    ..post('/simulate', simulate)

    ..get('/admin/users', getUsers)
    ..get('/admin/user/<id>', getUser)
    ..put('/admin/user/<id>', updateUser)
    ..post('/admin/lock_user', lockUser)
    ..post('/admin/unlock_user', unlockUser)
    ..post('/admin/reset_password', resetPassword);

  final int port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(public, InternetAddress.anyIPv4, port);

  logTo('Listen:${server.address.address}:${server.port}');
}
