import 'dart:io';
import 'package:full_pension_server/monitor.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'db.dart';
import 'auth.dart';
import 'user.dart';
import 'simulate.dart';
import 'debugLogger.dart';
import 'backup.dart';
import 'account.dart';
import 'income.dart';
import 'outgoing.dart';
import 'transfer.dart';
import 'admin.dart';
import 'middleware/auth.dart';
import 'middleware/api.dart';

import 'snapshotApi.dart';
import 'services/simulationService.dart';

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
      .addHandler(pub.call);

  // Protected pipeline (with auth)
  final protected = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(authMiddleware())
      .addMiddleware(monitor2)
      .addHandler(prot.call);

//  final cas = Cascade().add(public).add(protected).handler;

  final auth = Authentication(pension.getDb());

  // --- Public routes ---
  pub
    ..post('/register', auth.register)
    ..post('/login', auth.login)
    ..options('/<ignored|.*>', (Request request) => Response.ok(''));
    
  const validApiKey = 'your-secure-api-key-which-no-one-can-guess';

  // Add routes with API key authentication
  pub.post('/backup', apiKeyMiddleware(validApiKey)(backupHandler));
  pub.post('/restore', apiKeyMiddleware(validApiKey)(restoreHandler));
  pub.mount('/', protected);

  final simulationService = SimulationService(pension.getDb());
  
  final account = AccountApi(pension.getDb(), simulationService);
  final income = IncomeApi(pension.getDb(), simulationService);
  final outgoing = OutgoingApi(pension.getDb(), simulationService);
  final transfer = TransferApi(pension.getDb(), simulationService);
  final user = UserApi(pension.getDb());
  final admin = Admin(pension.getDb());
  final Simulate sim = Simulate();
  final snapshot = SnapshotApi(pension.getDb());

  // --- Protected routes ---
  prot
    ..mount('/account', account.router.call)
    ..mount('/income', income.router.call)
    ..mount('/outgoing', outgoing.router.call)
    ..mount('/transfer', transfer.router.call)
    ..mount('/snapshot', snapshot.router.call)
    ..mount('/simulation', simulationService.router.call)

    ..post('/user', user.insert)
    ..get('/user', user.select)
    ..get('/user/<id>', user.selectOne)
    ..put('/user/<id>', user.update)
//    ..delete('/user/<id>', user.delete)
    ..post('/admin/lock/<id>', admin.lock)
    ..post('/admin/unlock/<id>', admin.unlock)
    ..post('/admin/reset/<id>', admin.reset)
        
    ..post('/simulate', sim.simulate);

  final int port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(public, InternetAddress.anyIPv4, port);

  logTo('Listen:${server.address.address}:${server.port}');
}
