import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared/models/transfer.dart';
import 'db.dart';
import 'access.dart';

class TransferApi extends Access {
  TransferApi(super.db);

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
    final rows = db.select('SELECT * FROM transfer WHERE userid = ?', [userId]);

    final list = rows.map((row) => Transfer(
        id: row['id'],
        name: row['name'],
        amount: (row['amount'] as num).toDouble(),
        fromAccount: row['fromid'],
        intoAccount: row['intoid'],
        startAt: row['startat'],
        endAt: row['endat'],
        rate: (row['rate'] as num).toDouble(),
    )).toList();

    return Response.ok(
       jsonEncode(list.map((t) => t.toJson()).toList()),
       headers: {'content-type': 'application/json'}
    );
  }

  Future<Response> insert(Request request) async {
    final userId = request.context['uid'];
    final body = await request.readAsString();
    final data = jsonDecode(body);

    if (data['amount'] == null || data['startat'] == null) return fail('Missing fields');

    db.execute(
      '''INSERT INTO transfer (userid, name, fromid, intoid, amount, startat, endat, rate) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
      [userId, data['name'], data['fromid'], data['intoid'], data['amount'], data['startat'], data['endat'], data['rate']],
    );
    return ok();
  }

  Future<Response> update(Request request, String idStr) async {
    final userId = request.context['uid'];
    final id = int.tryParse(idStr);
    if (id == null) return fail('Invalid ID');
    
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final check = db.select('SELECT id FROM transfer WHERE id = ? AND userid = ?', [id, userId]);
    if (check.isEmpty) return fail('Not found');

    db.execute(
      '''UPDATE transfer SET name=?, fromid=?, intoid=?, amount=?, startat=?, endat=?, rate=? 
        WHERE id=?''',
      [data['name'], data['fromid'], data['intoid'], data['amount'], data['startat'], data['endat'], data['rate'], id],
    );

    return ok();
  }

  Future<Response> delete(Request request, String idStr) async {
    final userId = request.context['uid'];
    db.execute("DELETE FROM transfer WHERE id=? AND userid=?", [idStr, userId]);
    return ok();
  }
}
