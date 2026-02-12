import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared/models/transfer.dart';
import 'access.dart';
import 'services/simulationService.dart';

class TransferApi extends Access {
  final SimulationService? _simulationService;
  
  TransferApi(super.db, [this._simulationService]);

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

    final rows = db.select('SELECT * FROM transfer WHERE userid = ? LIMIT ? OFFSET ?', [userId, limit, offset]);
    
    // Get Total Count
    final countRows = db.select('SELECT COUNT(*) as c FROM transfer WHERE userid = ?', [userId]);
    final totalCount = countRows.first['c'] as int;

    final list = rows.map((row) => Transfer.fromDb(row)).toList();
    return Response.ok(
       jsonEncode({
          'data': list.map((t) => t.toJson()).toList(),
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
    
    // Parse into Transfer model
    final Transfer newTransfer;
    try {
      newTransfer = Transfer.fromJson(body);
    } catch (e) {
      return fail('Invalid transfer data: ${e.toString()}');
    }

    // Insert using model fields
    try {
      db.execute(
        '''INSERT INTO transfer (userid, name, fromid, intoid, amount, startat, endat, rate) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [userId, newTransfer.name, newTransfer.fromId, newTransfer.intoId, newTransfer.amount, newTransfer.startAt.toString(), newTransfer.endAt.toString(), newTransfer.rate],
      );
      _simulationService?.invalidateCache(userId as int);
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
    
    // Parse into Transfer model
    final Transfer updatedTransfer;
    try {
      updatedTransfer = Transfer.fromJson(body);
    } catch (e) {
      return fail('Invalid transfer data: ${e.toString()}');
    }

    // Check ownership
    final check = db.select('SELECT id FROM transfer WHERE id = ? AND userid = ?', [id, userId]);
    if (check.isEmpty) return fail('Not found');

    // Update using model fields
    try {
      db.execute(
        '''UPDATE transfer SET name=?, fromid=?, intoid=?, amount=?, startat=?, endat=?, rate=? 
          WHERE id=?''',
        [updatedTransfer.name, updatedTransfer.fromId, updatedTransfer.intoId, updatedTransfer.amount, updatedTransfer.startAt.toString(), updatedTransfer.endAt.toString(), updatedTransfer.rate, id],
      );
      _simulationService?.invalidateCache(userId as int);
      return ok();
    } catch (e) {
      return fail(e.toString());
    }
  }

  Future<Response> delete(Request request, String idStr) async {
    final userId = request.context['uid'];
    db.execute("DELETE FROM transfer WHERE id=? AND userid=?", [idStr, userId]);
    _simulationService?.invalidateCache(userId as int);
    return ok();
  }
}
