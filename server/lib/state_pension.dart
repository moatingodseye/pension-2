import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'db.dart';

// Create a state pension
Future<Response> createStatePension(Request req) async {
  final Database db = pension.getDb();
  final body = jsonDecode(await req.readAsString());
  final userId = req.context['uid'];

  if (userId == null || body['start_age'] == null || body['amount'] == null || body['interest_rate'] == null) {
    return Response(400, body: 'Missing fields');
  }

  db.execute(
    "INSERT INTO state_pensions (user_id, start_age, amount, interest_rate) VALUES (?, ?, ?, ?)",
    [userId, body['start_age'], body['amount'], body['interest_rate']],
  );

  return Response(
    200,
    body: jsonEncode({
      'success': true,
      'message': 'State created',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

// List all state pensions
Future<Response> listStatePensions(Request req) async {
  final Database db = pension.getDb();
  final rows = db.select("SELECT * FROM state_pensions WHERE user_id=?", [req.context['uid']]);
  if (rows.isEmpty)
    return Response.ok(jsonEncode({}));

  final data = rows.first;
  return Response.ok(jsonEncode({
    'id': data['id'],
    'start_age': data['start_age'],
    'amount': data['amount'],
    'interest_rate': data['interest_rate'],
  }));
}
