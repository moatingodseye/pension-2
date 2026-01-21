import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared/models/outgoing.dart';
import 'db.dart';
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
    final rows = db.select('SELECT * FROM outgoing WHERE userid = ?', [userId]);

    final list = rows.map((row) => Outgoing(
        id: row['id'],
        name: row['name'],
        amount: (row['amount'] as num).toDouble(),
        fromAccount: row['fromid'],
        startAt: row['startat'],
        endAt: row['endat'],
        rate: (row['rate'] as num).toDouble(),
    )).toList();

    return Response.ok(
       jsonEncode(list.map((o) => o.toJson()).toList()),
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
        [userId, newOutgoing.name, newOutgoing.fromAccount, newOutgoing.amount, newOutgoing.startAt, newOutgoing.endAt, newOutgoing.rate],
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
        [updatedOutgoing.name, updatedOutgoing.fromAccount, updatedOutgoing.amount, updatedOutgoing.startAt, updatedOutgoing.endAt, updatedOutgoing.rate, id],
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
