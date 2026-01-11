import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'access.dart';

class Account extends Access {
  Account(super.db);

  Future<Response> insert(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final userId = req.context['uid'];

    if (userId == null || body['name'] == null || body['amount'] == null || body['date'] == null || body['interest_rate'] == null) {
      return fail("invalid, missing fields");
    }

    db.execute(
      '''INSERT INTO account (userid, istype, name, amount, age, amountat, rate)
                      VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [userId, body['istype'], body['name'], body['amount'], body['age'], body['amountat'], body['rate']],
    );

    return ok();
  }

  // Update an existing account
  Future<Response> update(Request req, String id) async {
    final body = jsonDecode(await req.readAsString());
    final userId = req.context['uid'];

    // Validate the fields
    if (userId == null || body['name'] == null || body['amount'] == null || body['date'] == null || body['interest_rate'] == null) {
      return fail('invalid, missing fields');
    }

    // Ensure the pension pot exists for the given user and id
    final existing = db.select("SELECT * FROM account WHERE id=? AND userid=?", [id, userId]);

    if (existing.isEmpty) {
      return fail('No account with that id');
    }

    // Update the pension pot with the new values
    db.execute(      
      '''UPDATE account SET name=?, istype=?, amount=?, amountat=?, age=?, rate=? 
         WHERE id=? AND userid=?''',
      [body['name'], body['istype'], body['amount'], body['amountat'], body['age'], body['rate'], id, userId],
    );

    return ok();
  }

  // List all accounts
  Future<Response> select(Request req) async {
    final rows = db.select("SELECT * FROM account WHERE userid=?", [req.context['uid']]);
    final data = rows.map((r) => {
      'id': r['id'],
      'istype]': r['istype'],
      'name': r['name'],
      'amount': r['amount'],
      'amountat': r['amountat'],
      'rate': r['rate'],
      'age': r['age'],
    }).toList();

    return Response.ok(jsonEncode({'data': data}));
  }

  // Delete an account
  Future<Response> delete(Request req, String id) async {
    db.execute("DELETE FROM account WHERE id=? AND userid=?", [id, req.context['uid']]);
    return ok();
  }
}