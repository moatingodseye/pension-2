import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared/models/income.dart';
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
    
    // Pagination params
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
    final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

    final rows = db.select('SELECT * FROM income WHERE userid = ? LIMIT ? OFFSET ?', [userId, limit, offset]);
    
    // Get Total Count
    final countRows = db.select('SELECT COUNT(*) as c FROM income WHERE userid = ?', [userId]);
    final totalCount = countRows.first['c'] as int;

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
      jsonEncode({
          'data': list.map((i) => i.toJson()).toList(),
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
    
    // Parse into Income model
    final Income newIncome;
    try {
      newIncome = Income.fromJson(body);
    } catch (e) {
      return fail('Invalid income data: ${e.toString()}');
    }

    // Insert using model fields
    try {
      db.execute(
        '''INSERT INTO income (userid, name, intoid, amount, startat, endat, rate) 
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [userId, newIncome.name, newIncome.intoAccount, newIncome.amount, newIncome.startAt, newIncome.endAt, newIncome.rate],
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
    
    // Parse into Income model
    final Income updatedIncome;
    try {
      updatedIncome = Income.fromJson(body);
    } catch (e) {
      return fail('Invalid income data: ${e.toString()}');
    }

    // Check ownership
    final check = db.select('SELECT id FROM income WHERE id = ? AND userid = ?', [id, userId]);
    if (check.isEmpty) return fail('Not found');

    // Update using model fields
    try {
      db.execute(
        '''UPDATE income SET name=?, intoid=?, amount=?, startat=?, endat=?, rate=? 
          WHERE id=?''',
        [updatedIncome.name, updatedIncome.intoAccount, updatedIncome.amount, updatedIncome.startAt, updatedIncome.endAt, updatedIncome.rate, id],
      );
      return ok();
    } catch (e) {
      return fail(e.toString());
    }
  }

  Future<Response> delete(Request request, String idStr) async {
     // Implementation similar to other classes
    final userId = request.context['uid'];
    db.execute("DELETE FROM income WHERE id=? AND userid=?", [idStr, userId]);
    return ok();
  }
}
