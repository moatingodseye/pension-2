import 'package:flutter_test/flutter_test.dart';
import 'package:client/services/simulation_service.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';

void main() {
  group('SimulationService', () {
    test('Calculates simple compound interest', () {
      final acc = Account(
        id: 1,
        name: 'Pension',
        amount: 10000.0,
        type: AccountType.pension,
        amountAt: DateTime(2025, 1, 1),
        rate: 0.10, // 10%
      );

      SimulationService sim = new SimulationService();
      final result = sim.run(
        accountList: [acc],
        incomeList: [],
        outgoingList: [],
        transferList: [],
        dob: DateTime(1980, 1, 1),
      );

      expect(result.accountMap, hasLength(1));
      final pot = result.accountMap[0];
      
      // Year 0: Initial amount 10000
      // Year 1: 10000 * 1.10 = 11000
      
      // The service implementation:
      // accountSeries[id]![0] = 10000.
      // Loop y=0: accountSeries[id]![0] *= (1+rate).
      // So index 0 becomes End of Year 1? 
      // If logic is: y=0 is first year.
      
      // Let's check value at index 0.
      expect(pot[0], closeTo(11000, 1.0));
    });

    test('Monte Carlo generates range', () {
      final acc = Account(
        id: 1,
        name: 'Pension',
        amount: 10000.0,
        type: AccountType.pension,
        amountAt: DateTime(2025, 1, 1),
        rate: 0.05,
      );

      SimulationService sim = new SimulationService();
      final result = sim.run(
        accountList: [acc],
        incomeList: [],
        outgoingList: [],
        transferList: [],
        dob: DateTime(1980, 1, 1),
        volatility: 0.20, // High volatility
      );
      
      expect(result.montePath, isNotNull);
      expect(result.montePath!.length, 300); // We set 300 runs
      
      expect(result.monteMinList, isNotEmpty);
      expect(result.monteMaxList, isNotEmpty);
      
      // P75 should be >= P25
      expect(result.monteMaxList[0], greaterThanOrEqualTo(result.monteMinList[0]));
    });
  });
}
