import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'db.dart';
import 'access.dart';

class Transfer extends Access{
  Transfer(Database db) : super(db);

  // Create a transfer
  Future<Response> insert(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final userId = req.context['uid'];

    if (userId == null || body['amount'] == null || body['startat'] == null || body['rate'] == null) {
      return fail('invalid, missing fields');
    }

    db.execute(
      '''INSERT INTO transfer (userid, name, fromid, intoid, amount, startat, endat, rate) 
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [userId, body['name'], body['fromid'], body['intoid'], body['amount'], body['startat'], body['endat'] ?? null, body['rate']],
    );

    return ok();
  }

  // Update an existing transfer
  Future<Response> update(Request req, String id) async {
    final body = jsonDecode(await req.readAsString());
    final userId = req.context['uid'];

    // Validate the fields
    if (userId == null || body['amount'] == null || body['startat'] == null || body['rate'] == null) {
      return fail('invalid, missing fields');
    }

    // Ensure the drawdown exists for the given user and id
    final existing = db.select("SELECT * FROM transfer WHERE id=? AND userid=?", [id, userId]);

    if (existing.isEmpty) {
      return fail('No transfer found with that id');
    }

    // Update the drawdown with the new values
    db.execute(
      '''UPDATE transfer SET name=?, fromid=?, intoid=?, amount=?, startat=?, endat=?, rate=? 
        WHERE id=? AND userid=?''',
      [body['name'], body['fromid'], body['intoid'], body['amount'], body['startat'], body['endat'], body['rate'], id, userId],
    );

    return ok();
  }

  // List all transfer
  Future<Response> select(Request req) async {
    final rows = db.select("SELECT * FROM transfer WHERE userid=?", [req.context['uid']]);
    final data = rows.map((r) => {
      'id': r['id'],
      'name': r['name'],
      'fromid': r['fromid'],
      'intoid': r['intoid'],
      'amount': r['amount'],
      'startat': r['startat'],
      'endat': r['endat'],
      'rate': r['rate'],
    }).toList();

    return Response.ok(jsonEncode({'data': data}));
  }

  // Delete a transfer
  Future<Response> delete(Request req, String id) async {
    final Database db = pension.getDb();
    db.execute("DELETE FROM transfer WHERE id=? AND userid=?", [id, req.context['uid']]);
    return ok();
  }
}
