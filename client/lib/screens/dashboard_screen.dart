import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/account_provider.dart';
import '../providers/income_provider.dart';
import '../providers/outgoing_provider.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/account.dart';
import '../widgets/app_card.dart';
import '../widgets/forms/account_form_dialog.dart';
import '../widgets/forms/income_form_dialog.dart';
import '../widgets/forms/outgoing_form_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).load();
      Provider.of<IncomeProvider>(context, listen: false).load();
      Provider.of<OutgoingProvider>(context, listen: false).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AccountProvider, IncomeProvider, OutgoingProvider>(
      builder: (ctx, accProv, incProv, outProv, _) {
        // Calculate Totals
        double totalPension = 0;
        double totalSavings = 0;
        for (Account a in accProv.accounts) {
          if (a.type == AccountType.pension) {
            totalPension += a.amount;
          } else {
            totalSavings += a.amount;
          }
        }
        double totalNetWorth = totalPension + totalSavings;

        double totalMonthlyIncome = incProv.incomes.fold(0, (sum, i) => sum + i.amount);
        double totalMonthlyOutgoing = outProv.outgoings.fold(0, (sum, o) => sum + o.amount);
        double netMonthly = totalMonthlyIncome - totalMonthlyOutgoing;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // Key Metrics Row
              Row(
                children: [
                  Expanded(child: _StatCard(title: 'Net Worth', value: totalNetWorth, icon: Icons.account_balance_wallet, color: Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _StatCard(title: 'Pension Pot', value: totalPension, icon: Icons.savings, color: Colors.purple)),
                  const SizedBox(width: 16),
                  Expanded(child: _StatCard(title: 'Savings', value: totalSavings, icon: Icons.attach_money, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 16),
              // Cash Flow Row
              Row(
                children: [
                   Expanded(child: _StatCard(title: 'Monthly Income', value: totalMonthlyIncome, icon: Icons.arrow_downward, color: Colors.teal, isSmall: true)),
                   const SizedBox(width: 16),
                   Expanded(child: _StatCard(title: 'Monthly Outgoing', value: totalMonthlyOutgoing, icon: Icons.arrow_upward, color: Colors.redAccent, isSmall: true)),
                   const SizedBox(width: 16),
                   Expanded(child: _StatCard(title: 'Net Monthly', value: netMonthly, icon: Icons.waterfall_chart, color: netMonthly >= 0 ? Colors.green : Colors.red, isSmall: true)),
                ],
              ),

              const SizedBox(height: 24),
              
              // Main Content Area: Charts & Quick Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Asset Allocation Chart
                  Expanded(
                    flex: 2,
                    child: AppCard(
                      title: 'Asset Allocation',
                      child: SizedBox(
                        height: 300,
                        child: totalNetWorth == 0 
                                ? const Center(child: Text('No Data available to display chart', style: TextStyle(color: Colors.grey)))
                                : Row(
                                  children: [
                                    Expanded(
                                      child: PieChart(
                                        PieChartData(
                                          sections: [
                                            if (totalPension > 0)
                                              PieChartSectionData(
                                                value: totalPension,
                                                title: '${(totalPension/totalNetWorth*100).toStringAsFixed(0)}%',
                                                color: Colors.purple.shade400,
                                                radius: 80,
                                                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                                badgeWidget: _Badge(Icons.savings, size: 40, borderColor: Colors.purple.shade400),
                                                badgePositionPercentageOffset: .98,
                                              ),
                                            if (totalSavings > 0)
                                              PieChartSectionData(
                                                value: totalSavings,
                                                title: '${(totalSavings/totalNetWorth*100).toStringAsFixed(0)}%',
                                                color: Colors.green.shade400,
                                                radius: 80,
                                                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                                badgeWidget: _Badge(Icons.attach_money, size: 40, borderColor: Colors.green.shade400),
                                                badgePositionPercentageOffset: .98,
                                              ),
                                          ],
                                          sectionsSpace: 4,
                                          centerSpaceRadius: 40,
                                        ),
                                      ),
                                    ),
                                    // Legend
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _LegendItem(color: Colors.purple.shade400, label: 'Pension', value: totalPension),
                                        const SizedBox(height: 8),
                                        _LegendItem(color: Colors.green.shade400, label: 'Savings', value: totalSavings),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                  ],
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Quick Actions Panel
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final bool isSmall;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: isSmall ? 20 : 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  '£${value.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 18 : 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Text('(£${value.toStringAsFixed(0)})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color borderColor;

  const _Badge(this.icon, {required this.size, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(2, 2),
            blurRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(child: Icon(icon, color: borderColor, size: size * 0.6)),
    );
  }
}
