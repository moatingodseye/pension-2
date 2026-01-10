import 'dart:io';
import 'dart:isolate';
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
import 'account.dart';
import 'income.dart';
import 'outgoing.dart';
import 'transfer.dart';
import 'admin.dart';
import 'middleware/auth.dart';
import 'middleware/api.dart';

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

  final auth = new Authentication(pension.getDb());

  // --- Public routes ---
  pub
    ..post('/register', auth.register)
    ..post('/login', auth.login);
    
  const validApiKey = 'your-secure-api-key-which-no-one-can-guess';

  // Add routes with API key authentication
  pub.post('/backup', apiKeyMiddleware(validApiKey)(backupHandler));
  pub.post('/restore', apiKeyMiddleware(validApiKey)(restoreHandler));
  pub.mount('/', protected);

  final account = new Account(pension.getDb());
  final income = new Income(pension.getDb());
  final outgoing = new Outgoing(pension.getDb());
  final transfer = new Transfer(pension.getDb());
  final user = new User(pension.getDb());
  final admin = new Admin(pension.getDb());

  // --- Protected routes ---
  prot
    ..post('/account', account.insert)
    ..put('/account/<id>', account.update)
    ..get('/account', account.select)
    ..delete('/account/<id>', account.delete)

    ..post('/income', income.insert)
    ..put('/income/<id>', income.update)
    ..get('/income', income.select)
    ..delete('/income/<id>', income.delete)

    ..post('/outgoing', outgoing.insert)
    ..put('/outgoing/<id>', outgoing.update)
    ..get('/outgoing', outgoing.select)
    ..delete('/outgoing/<id>', outgoing.delete)

    ..post('/transfer', transfer.insert)
    ..put('/transfer/<id>', transfer.update)
    ..get('/transfer', transfer.select)
    ..delete('/transfer/<id>', transfer.delete)

    ..post('/user', user.insert)
    ..get('/user', user.select)
    ..get('/user/<id>', user.selectOne)
    ..put('/user/<id>', user.update)
//    ..delete('/user/<id>', user.delete)
    ..post('/admin/lock/<id>', admin.lock)
    ..post('/admin/unlock/<id>', admin.unlock)
    ..post('/admin/reset/<id>', admin.reset)
        
    ..post('/simulate', simulate);

  final int port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(public, InternetAddress.anyIPv4, port);

  logTo('Listen:${server.address.address}:${server.port}');
}
