import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'db.dart';

// Create a pension pot
Future<Response> createPensionPot(Request req) async {
  final Database db = pension.getDb();
  final body = jsonDecode(await req.readAsString());
  final userId = req.context['uid'];

  if (userId == null || body['name'] == null || body['amount'] == null || body['date'] == null || body['interest_rate'] == null) {
    return Response(400, body: 'Missing fields');
  }

  db.execute(
    "INSERT INTO pension_pots (userId, name, amount, date, interest_rate) VALUES (?, ?, ?, ?, ?)",
    [userId, body['name'], body['amount'], body['date'], body['interest_rate']],
  );

  return Response(
    200,
    body: jsonEncode({
      'success': true,
      'message': 'Pension created',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

// Update an existing pension pot
Future<Response> updatePensionPot(Request req, String id) async {
  final Database db = pension.getDb();
  final body = jsonDecode(await req.readAsString());
  final userId = req.context['uid'];

  // Validate the fields
  if (userId == null || body['name'] == null || body['amount'] == null || body['date'] == null || body['interest_rate'] == null) {
    return Response(
      400,
      body: jsonEncode({
        'success': false,
        'error': 'Missing fields',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Ensure the pension pot exists for the given user and id
  final existingPot = db.select("SELECT * FROM pension_pots WHERE id=? AND userId=?", [id, userId]);

  if (existingPot.isEmpty) {
    return Response(
      404,
      body: jsonEncode({
        'success': false,
        'error': 'Pension pot not found',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Update the pension pot with the new values
  db.execute(
    "UPDATE pension_pots SET name=?, amount=?, date=?, interest_rate=? WHERE id=? AND userId=?",
    [body['name'], body['amount'], body['date'], body['interest_rate'], id, userId],
  );

  return Response(
    200,
    body: jsonEncode({
      'success': true,
      'message': 'Pension pot updated',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

// List all pension pots
Future<Response> listPensionPots(Request req) async {
  final Database db = pension.getDb();
  final rows = db.select("SELECT * FROM pension_pots WHERE userId=?", [req.context['uid']]);
  final data = rows.map((r) => {
    'id': r['id'],
    'name': r['name'],
    'amount': r['amount'],
    'date': r['date'],
    'interest_rate': r['interest_rate'],
  }).toList();

  return Response.ok(jsonEncode({'data': data}));
}

// Delete a pension pot
Future<Response> deletePensionPot(Request req, String id) async {
  final Database db = pension.getDb();
  db.execute("DELETE FROM pension_pots WHERE id=? AND userId=?", [id, req.context['uid']]);
  return Response(
    200,
    body: jsonEncode({
      'success': true,
      'message': 'Pension deleted',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}
