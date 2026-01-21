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
    
    // Parse JSON
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString());
    } catch (e) {
      return fail('Invalid JSON format');
    }
    
    // Parse into Account model
    final Account newAccount;
    try {
      newAccount = Account.fromJson(body);
    } catch (e) {
      return fail('Invalid account data: ${e.toString()}');
    }
    
    // Insert using model fields
    try {
      db.execute(
        '''INSERT INTO account (userid, istype, name, amount, age, amountat, rate)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          userId,
          newAccount.type.id,
          newAccount.name,
          newAccount.amount,
          newAccount.age,
          newAccount.amountAt.toIso8601String().split('T')[0],
          newAccount.rate
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
    
    // Parse JSON
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString());
    } catch (e) {
      return fail('Invalid JSON format');
    }
    
    // Parse into Account model
    final Account updatedAccount;
    try {
      updatedAccount = Account.fromJson(body);
    } catch (e) {
      return fail('Invalid account data: ${e.toString()}');
    }
    
    // Check ownership
    final check = db.select('SELECT id FROM account WHERE id = ? AND userid = ?', [id, userId]);
    if (check.isEmpty) return fail('Not found/Access Denied');

    // Update using model fields
    try {
      db.execute(
        '''UPDATE account 
           SET istype=?, name=?, amount=?, age=?, amountat=?, rate=?
           WHERE id=?''',
        [
          updatedAccount.type.id,
          updatedAccount.name,
          updatedAccount.amount,
          updatedAccount.age,
          updatedAccount.amountAt.toIso8601String().split('T')[0],
          updatedAccount.rate,
          id
        ],
      );
      return ok();
    } catch (e) {
      return fail(e.toString());
    }
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