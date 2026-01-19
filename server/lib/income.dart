import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared/models/income.dart';
import 'db.dart';
import 'access.dart';

class IncomeApi extends Access {
  IncomeApi(super.db);

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
    final rows = db.select('SELECT * FROM income WHERE userid = ?', [userId]);

    final list = rows.map((row) => Income(
        id: row['id'],
        name: row['name'],
        amount: (row['amount'] as num).toDouble(),
        intoAccount: row['intoid'],
        startAt: row['startat'],
        endAt: row['endat'],
        rate: (row['rate'] as num).toDouble(),
    )).toList();

    return Response.ok(
      jsonEncode(list.map((i) => i.toJson()).toList()),
      headers: {'content-type': 'application/json'}
    );
  }

  Future<Response> insert(Request request) async {
    final userId = request.context['uid'];
    final body = await request.readAsString();
    final data = jsonDecode(body);

    if (data['amount'] == null || data['startat'] == null) return fail('Missing fields');

    db.execute(
      '''INSERT INTO income (userid, name, intoid, amount, startat, endat, rate) 
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [userId, data['name'], data['intoid'], data['amount'], data['startat'], data['endat'], data['rate']],
    );

    return ok();
  }

  Future<Response> update(Request request, String idStr) async {
    final userId = request.context['uid'];
    final id = int.tryParse(idStr);
    if (id == null) return fail('Invalid ID');
    
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final check = db.select('SELECT id FROM income WHERE id = ? AND userid = ?', [id, userId]);
    if (check.isEmpty) return fail('Not found');

    db.execute(
      '''UPDATE income SET name=?, intoid=?, amount=?, startat=?, endat=?, rate=? 
        WHERE id=?''',
      [data['name'], data['intoid'], data['amount'], data['startat'], data['endat'], data['rate'], id],
    );

    return ok();
  }

  Future<Response> delete(Request request, String idStr) async {
     // Implementation similar to other classes
    final userId = request.context['uid'];
    db.execute("DELETE FROM income WHERE id=? AND userid=?", [idStr, userId]);
    return ok();
  }
}
