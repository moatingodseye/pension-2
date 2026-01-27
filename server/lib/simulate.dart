import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';
import 'debuglogger.dart'; // Import server logger
import 'package:shared/models/account.dart';
import 'package:shared/models/user.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';
import 'package:shared/models/simulation_result.dart';
import 'package:shared/models/simulate.dart' as shared;

class Simulate {
  List<Account>? accountList;
  List<Income>? incomeList;
  List<Outgoing>? outgoingList;
  List<Transfer>? transferList;
  User? user;

  bool load(int uid) {
    final db = pension.getDb();

    glog.info('Simulate request received for user: $uid');

    final userRow = db.select("SELECT * FROM user WHERE id=?", [uid]);
    if (userRow.isEmpty) {
      glog.warning('Simulate failed: User $uid not found');
      return false;
    }

    user = User.fromDb(userRow.first);
    final accRow = db.select("SELECT * FROM account WHERE userId=?", [uid]);
    final incRow = db.select("SELECT * FROM income WHERE userId=?", [uid]);
    final outRow = db.select("SELECT * FROM outgoing WHERE userId=?", [uid]);
    final traRow = db.select("SELECT * FROM transfer WHERE userId=?", [uid]);

    // ... (Models mapping) ...
    accountList = accRow.map((r) => Account.fromDb(r)).toList();
    incomeList = incRow.map((r) => Income.fromDb(r)).toList();
    outgoingList = outRow.map((r) => Outgoing.fromDb(r)).toList();
    transferList = traRow.map((r) => Transfer.fromDb(r)).toList();

    return true;
  }

  Future<Response> simulate(Request req) async {
    final uid = req.context['uid'] as int;
    glog.info('Simulate request received for user: $uid');

    if (!load(uid)) {
      glog.warning('Simulate failed: User $uid not found');
      return Response.notFound('User not found');
    } else {
      final bodyStr = await req.readAsString();
      final decoded = bodyStr.isNotEmpty ? jsonDecode(bodyStr) : null;
      final Map<String, dynamic>? body =
          decoded is Map<String, dynamic> ? decoded : null;
      final double volatility =
          body != null ? (body['volatility'] as num?)?.toDouble() ?? 1.0 : 1.0;
      final double rateAdjustment =
          body != null ? (body['rate_adjustment'] as num?)?.toDouble() ?? 1.0 : 1.0;

      if (accountList!.isEmpty) {
        return Response.ok(
            jsonEncode(SimulationResult(
                    nameList: [],
                    sumList: [],
                    incomeList: [],
                    accountMap: [],
                    monteMinList: [],
                    monteMaxList: [],
                    ageList: [],
                    sumPotMin: 0,
                    sumPotMax: 100,
                    incomeMin: 0,
                    incomeMax: 100,
                    xAxisMin: 0,
                    xAxisMax: 100)
                .toJson()),
            headers: {'Content-Type': 'application/json'});
      }

      shared.Simulate sim = shared.Simulate(accountList, incomeList, outgoingList, transferList, user!);

      final result = sim.simulate(volatility,rateAdjustment);

      return Response.ok(jsonEncode(result!.toJson()),
          headers: {'Content-Type': 'application/json'});
    }
  }
}