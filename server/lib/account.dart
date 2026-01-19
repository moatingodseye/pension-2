import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'db.dart';
import 'access.dart';

class AccountApi extends Access {
  AccountApi(super.db);
  
  Router get router {
    final router = Router();
    router.get('/', select);
    router.post('/', insert);
    router.put('/<id>', update);
    router.delete('/<id>', delete);
    return router;
  }

  // List all accounts
  Future<Response> select(Request request) async {
    final userId = request.context['uid'];
    final rows = db.select('SELECT * FROM account WHERE userid = ?', [userId]);

    final accounts = rows.map((row) {
        return Account(
            id: row['id'],
            name: row['name'],
            amount: (row['amount'] as num).toDouble(),
            type: AccountType.fromId(row['istype']),
            amountAt: DateTime.parse(row['amountat']),
            rate: (row['rate'] as num).toDouble(),
            age: row['age'] as int? ?? 0,
        );
    }).toList();

    return Response.ok(
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
      headers: {'content-type': 'application/json'},
    );
  }

  // Create an account
  Future<Response> insert(Request request) async {
    final userId = request.context['uid'];
    final body = await request.readAsString();
    
    try {
        // Parsing as Model (ID will be null)
        // Note: For parsing partial JSON that might not fully match strict model (e.g. ID null),
        // we might sometimes use map directly, but let's try strict.
        // Actually, our shared model allows null ID.
        // However, "istype" in JSON coming from client might be int, matched by AccountType.fromId in fromJson if we adapted it,
        // but currently our Account.fromJson expects 'istype' as int.
        
        final Map<String, dynamic> data = jsonDecode(body);
        
        // Manual validation for required fields
        if (data['name'] == null || data['amount'] == null) {
             return fail('Missing fields');
        }

        // Use standard DB insert
        // We can't use Model.fromJson directly if client sends different keys or if we want to trust just specific fields.
        // But the goal is to use the model.
        // Let's rely on manual mapping for insert to be safe and clear.
        
        db.execute(
          '''INSERT INTO account (userid, istype, name, amount, age, amountat, rate)
             VALUES (?, ?, ?, ?, ?, ?, ?)''',
          [
            userId,
            data['istype'], // int from client
            data['name'],
            data['amount'],
            data['age'] ?? 0,
            data['amountat'],
            data['rate']
          ],
        );
        return ok();
    } catch (e) {
        return fail(e.toString());
    }
  }

  // Update an existing account
  Future<Response> update(Request request, String idStr) async {
    final userId = request.context['uid'];
    final id = int.tryParse(idStr);
    if (id == null) return fail('Invalid ID');
    
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    // Check ownership
    final check = db.select('SELECT id FROM account WHERE id = ? AND userid = ?', [id, userId]);
    if (check.isEmpty) return fail('Not found/Access Denied');

    db.execute(
      '''UPDATE account 
         SET istype=?, name=?, amount=?, age=?, amountat=?, rate=?
         WHERE id=?''',
      [
        data['istype'],
        data['name'],
        data['amount'],
        data['age'] ?? 0,
        data['amountat'],
        data['rate'],
        id
      ],
    );

    return ok();
  }

  // Delete an account
  Future<Response> delete(Request request, String idStr) async {
    final userId = request.context['uid'];
    final id = int.tryParse(idStr);
    if (id == null) return fail('Invalid ID');

    db.execute('DELETE FROM account WHERE id = ? AND userid = ?', [id, userId]);
    return ok();
  }
}