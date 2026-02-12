import 'package:shared/logic.dart';
import 'package:test/test.dart';

void main() {
  test('Monte Carlo Run Basic', () {
    final result = runMonteCarlo(
      initialPot: 100000,
      years: 10,
      simulations: 100,
      annualReturn: 0.05,
      annualVolatility: 0.15,
      monthlyContribution: 0,
    );

    expect(result.paths.length, 50, reason: 'Should return 50 display paths');
    expect(result.median.length, 11, reason: 'Yearly steps 0..10');
    expect(result.median.first, 100000);
    
    // Check that median at end is roughly expected (compounded)
    // 100k * 1.05^10 ~= 162k
    // But volatility drags it down a bit (geometric brownian motion median is lower than mean)
    // Median ~ s0 * exp((mu - 0.5*sigma^2)*T)
    // 0.05 - 0.5*0.15^2 = 0.05 - 0.01125 = 0.03875
    // exp(0.03875 * 10) = exp(0.3875) ~= 1.47
    // 147k
    print('Median end: ${result.median.last}');
  });
}
