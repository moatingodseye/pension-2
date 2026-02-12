import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared/models/snapshot.dart';
import 'access.dart';

class SnapshotApi extends Access {
  SnapshotApi(super.db);

  Router get router {
    final router = Router();
    router.post('/', insert);
    router.get('/<accountId>', select);
    return router;
  }

  // Create a snapshot
  Future<Response> insert(Request req) async {
    final userId = req.context['uid'];
    
    // Parse JSON
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await req.readAsString());
    } catch (e) {
      return fail('Invalid JSON format');
    }

    final AccountSnapshot snapshot;
    try {
      snapshot = AccountSnapshot.fromJson(body);
    } catch (e) {
      return fail('Invalid snapshot data: $e');
    }

    // Verify account ownership
    final check = db.select('SELECT id FROM account WHERE id = ? AND userId = ?', [snapshot.accountId, userId]);
    if (check.isEmpty) {
      return fail('Account not found or access denied');
    }

    try {
      db.execute(
        'INSERT INTO accountSnapshot (accountId, value, date) VALUES (?, ?, ?)',
        [snapshot.accountId, snapshot.value, snapshot.date.toIso8601String()],
      );
      return ok();
    } catch (e) {
      return fail(e.toString());
    }
  }

  // Get snapshots for an account
  Future<Response> select(Request req, String accountIdStr) async {
    final userId = req.context['uid'];
    final accountId = int.tryParse(accountIdStr);
    
    if (accountId == null) return fail('Invalid Account ID');

    // Verify account ownership
    final check = db.select('SELECT id FROM account WHERE id = ? AND userId = ?', [accountId, userId]);
    if (check.isEmpty) {
       return fail('Account not found or access denied');
    }

    final rows = db.select(
      'SELECT * FROM accountSnapshot WHERE accountId = ? ORDER BY date ASC',
      [accountId]
    );

    final snapshots = rows.map((r) => AccountSnapshot.fromDb(r)).toList();

    return Response.ok(
      jsonEncode({'data': snapshots.map((s) => s.toJson()).toList()}),
      headers: {'content-type': 'application/json'},
    );
  }
}
