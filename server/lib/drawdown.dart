import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';

// Create a drawdown
Future<Response> createDrawdown(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final userId = req.context['uid'];

  if (userId == null || body['amount'] == null || body['start_date'] == null || body['interest_rate'] == null) {
    return Response(400, body: 'Missing fields');
  }

  db.execute(
    "INSERT INTO drawdowns (user_id, pension_pot_id, amount, start_date, end_date, interest_rate) VALUES (?, ?, ?, ?, ?, ?)",
    [userId, body['pension_pot_id'], body['amount'], body['start_date'], body['end_date'] ?? null, body['interest_rate']],
  );

  return Response.ok('Drawdown created');
}

// Update an existing drawdown
Future<Response> updateDrawdown(Request req, String id) async {
  final body = jsonDecode(await req.readAsString());
  final userId = req.context['uid'];

  // Validate the fields
  if (userId == null || body['amount'] == null || body['start_date'] == null || body['interest_rate'] == null) {
    return Response(
      400,
      body: jsonEncode({
        'success': false,
        'error': 'Missing fields',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Ensure the drawdown exists for the given user and id
  final existingDrawdown = db.select("SELECT * FROM drawdowns WHERE id=? AND user_id=?", [id, userId]);

  if (existingDrawdown.isEmpty) {
    return Response(
      404,
      body: jsonEncode({
        'success': false,
        'error': 'Drawdown not found',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Update the drawdown with the new values
  db.execute(
    "UPDATE drawdowns SET pension_pot_id=?, amount=?, start_date=?, end_date=?, interest_rate=? WHERE id=? AND user_id=?",
    [body['pension_pot_id'], body['amount'], body['start_date'], body['end_date'], body['interest_rate'], id, userId],
  );

  return Response(
    200,
    body: jsonEncode({
      'success': true,
      'message': 'Drawdown updated',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

// List all drawdowns
Future<Response> listDrawdowns(Request req) async {
  final rows = db.select("SELECT * FROM drawdowns WHERE user_id=?", [req.context['uid']]);
  final data = rows.map((r) => {
    'id': r['id'],
    'pension_pot_id': r['pension_pot_id'],
    'amount': r['amount'],
    'start_date': r['start_date'],
    'end_date': r['end_date'],
    'interest_rate': r['interest_rate'],
  }).toList();

  return Response.ok(jsonEncode({'data': data}));
}

// Delete a drawdown
Future<Response> deleteDrawdown(Request req, String id) async {
  db.execute("DELETE FROM drawdowns WHERE id=? AND user_id=?", [id, req.context['uid']]);
  return Response.ok('Deleted');
}

