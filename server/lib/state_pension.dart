import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';

// Create a state pension
Future<Response> createStatePension(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final userId = req.context['uid'];

  if (userId == null || body['start_age'] == null || body['amount'] == null || body['interest_rate'] == null) {
    return Response(400, body: 'Missing fields');
  }

  db.execute(
    "INSERT INTO state_pensions (user_id, start_age, amount, interest_rate) VALUES (?, ?, ?, ?)",
    [userId, body['start_age'], body['amount'], body['interest_rate']],
  );

  return Response.ok('State pension created');
}

// List all state pensions
Future<Response> listStatePensions(Request req) async {
  final rows = db.select("SELECT * FROM state_pensions WHERE user_id=?", [req.context['uid']]);
  final data = rows.map((r) => {
    'id': r['id'],
    'start_age': r['start_age'],
    'amount': r['amount'],
    'interest_rate': r['interest_rate'],
  }).toList();

  return Response.ok(jsonEncode({'data': data}));
}
