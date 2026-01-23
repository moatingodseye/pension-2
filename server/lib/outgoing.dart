import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared/models/outgoing.dart';
import 'access.dart';

class OutgoingApi extends Access {
  OutgoingApi(super.db);

  Router get router {
    final router = Router();
    router.get('/', select);
    router.post('/', insert);
    router.put('/<id>', update);
    router.delete('/<id>', delete);
    return router;
  }

  Future<Response> select(Request request) async {
    final userId = request.context['uid'];
    
    // Pagination params
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

    final rows = db.select('SELECT * FROM outgoing WHERE userid = ? LIMIT ? OFFSET ?', [userId, limit, offset]);
    
    // Get Total Count
    final countRows = db.select('SELECT COUNT(*) as c FROM outgoing WHERE userid = ?', [userId]);
    final totalCount = countRows.first['c'] as int;

    final list = rows.map((row) => Outgoing.fromDb(row)).toList();

    return Response.ok(
       jsonEncode({
          'data': list.map((o) => o.toJson()).toList(),
          'count': totalCount,
          'limit': limit,
          'offset': offset
       }),
       headers: {'content-type': 'application/json'}
    );
  }

  Future<Response> insert(Request request) async {
    final userId = request.context['uid'];
    
    // Parse JSON
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString());
    } catch (e) {
      return fail('Invalid JSON format');
    }
    
    // Parse into Outgoing model
    final Outgoing newOutgoing;
    try {
      newOutgoing = Outgoing.fromJson(body);
    } catch (e) {
      return fail('Invalid outgoing data: ${e.toString()}');
    }

    // Insert using model fields
    try {
      db.execute(
        '''INSERT INTO outgoing (userid, name, fromid, amount, startat, endat, rate) 
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [userId, newOutgoing.name, newOutgoing.fromId, newOutgoing.amount, newOutgoing.startAt, newOutgoing.endAt, newOutgoing.rate],
      );
      return ok();
    } catch (e) {
      return fail(e.toString());
    }
  }

  Future<Response> update(Request request, String idStr) async {
    final userId = request.context['uid'];
    final id = int.tryParse(idStr);
    if (id == null) return fail('Invalid ID');
    
    // Parse JSON
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString());
    } catch (e) {
      return fail('Invalid JSON format');
    }
    
    // Parse into Outgoing model
    final Outgoing updatedOutgoing;
    try {
      updatedOutgoing = Outgoing.fromJson(body);
    } catch (e) {
      return fail('Invalid outgoing data: ${e.toString()}');
    }

    // Check ownership
    final check = db.select('SELECT id FROM outgoing WHERE id = ? AND userid = ?', [id, userId]);
    if (check.isEmpty) return fail('Not found');

    // Update using model fields
    try {
      db.execute(
        '''UPDATE outgoing SET name=?, fromid=?, amount=?, startat=?, endat=?, rate=? 
          WHERE id=?''',
        [updatedOutgoing.name, updatedOutgoing.fromId, updatedOutgoing.amount, updatedOutgoing.startAt, updatedOutgoing.endAt, updatedOutgoing.rate, id],
      );
      return ok();
    } catch (e) {
      return fail(e.toString());
    }
  }

  Future<Response> delete(Request request, String idStr) async {
    final userId = request.context['uid'];
    db.execute("DELETE FROM outgoing WHERE id=? AND userid=?", [idStr, userId]);
    return ok();
  }
}
