import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../db.dart';
import '../isolateWorker.dart';
import 'package:shared/models.dart';
import 'package:shared/logic.dart';

class SimulationService {
  final sqlite.Database _db;
  // Cache results: UserId -> Map<AccountId, Result>
  final Map<int, Map<int, MonteCarloResult>> _cache = {};

  SimulationService(this._db);

  Router get router {
    final router = Router();
    router.get('/dashboard', getDashboard);
    return router;
  }

  // Endpoint to get simulation data for dashboard
  Future<Response> getDashboard(Request req) async {
    final userId = req.context['uid'] as int;
    
    if (!_cache.containsKey(userId)) {
      await refresh(userId);
    }

    final results = _cache[userId];
    // Convert to JSON friendly format
    // Map<String, dynamic> response = {};
    // results?.forEach((k, v) => response[k.toString()] = v.toJson());

    final List<Map<String, dynamic>> list = [];
    if (results != null) {
      results.forEach((accountId, result) {
        list.add({
          'accountId': accountId,
          'result': result.toJson()
        });
      });
    }

    return Response.ok(
      jsonEncode({'data': list}),
      headers: {'content-type': 'application/json'}
    );
  }

  // Trigger a background simulation
  Future<void> refresh(int userId) async {
    // 1. Fetch user accounts
    final rows = _db.select('SELECT * FROM account WHERE userId = ?', [userId]);
    if (rows.isEmpty) {
      _cache[userId] = {};
      return;
    }

    final List<Map<String, dynamic>> accounts = rows.map((r) => {
      'id': r['id'],
      'amount': r['amount'],
      'rate': r['rate'],
      'name': r['name']
    }).toList();

    // 2. Spawn Isolate
    final receivePort = ReceivePort();
    await Isolate.spawn(simulationWorker, SimulationRequest(receivePort.sendPort, accounts));

    // 3. Wait for result
    final response = await receivePort.first as SimulationResponse;
    
    // 4. Update Cache
    _cache[userId] = response.results;
  }

  // Invalidate cache when account data changes
  void invalidateCache(int userId) {
    _cache.remove(userId);
  }
}
