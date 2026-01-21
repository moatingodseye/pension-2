import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared/models/account.dart';
import '../providers/account_provider.dart';
import '../providers/income_provider.dart';
import '../providers/outgoing_provider.dart';
import 'account_screen.dart';
import 'income_screen.dart';
import 'outgoing_screen.dart';
import '../models/account_type.dart';

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
        for (var a in accProv.accounts) {
          if (a.type == AccountType.pension) {
            totalPension += a.amount;
          } else {
            totalSavings += a.amount;
          }
        }
        double totalNetWorth = totalPension + totalSavings;

        double totalMonthlyIncome = incProv.incomes.fold(0, (sum, i) => sum + i.amount);
        double totalMonthlyOutgoing = outProv.outgoings.fold(0, (sum, o) => sum + o.amount);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Financial Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Summary Cards
              Row(
                children: [
                  _SummaryCard(title: 'Net Worth', value: totalNetWorth, color: Colors.blue),
                  const SizedBox(width: 8),
                  _SummaryCard(title: 'Pension', value: totalPension, color: Colors.purple),
                  const SizedBox(width: 8),
                  _SummaryCard(title: 'Savings', value: totalSavings, color: Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SummaryCard(title: 'Monthly In', value: totalMonthlyIncome, color: Colors.teal),
                  const SizedBox(width: 8),
                  _SummaryCard(title: 'Monthly Out', value: totalMonthlyOutgoing, color: Colors.red),
                  const SizedBox(width: 8),
                  _SummaryCard(title: 'Net Monthly', value: totalMonthlyIncome - totalMonthlyOutgoing, 
                      color: (totalMonthlyIncome - totalMonthlyOutgoing) >= 0 ? Colors.green : Colors.red),
                ],
              ),

              const SizedBox(height: 24),
              
              // Charts & Actions Row
              SizedBox(
                height: 300,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pie Chart
                    Expanded(
                      flex: 2,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Asset Allocation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Expanded(
                                child: totalNetWorth == 0 
                                ? const Center(child: Text('No Data'))
                                : PieChart(
                                  PieChartData(
                                    sections: [
                                      if (totalPension > 0)
                                        PieChartSectionData(
                                          value: totalPension,
                                          title: '${(totalPension/totalNetWorth*100).toStringAsFixed(0)}%',
                                          color: Colors.purple,
                                          radius: 50,
                                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      if (totalSavings > 0)
                                        PieChartSectionData(
                                          value: totalSavings,
                                          title: '${(totalSavings/totalNetWorth*100).toStringAsFixed(0)}%',
                                          color: Colors.green,
                                          radius: 50,
                                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                    ],
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.circle, color: Colors.purple, size: 12), SizedBox(width: 4), Text('Pension'),
                                  SizedBox(width: 16),
                                  Icon(Icons.circle, color: Colors.green, size: 12), SizedBox(width: 4), Text('Savings'),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Quick Actions
                    Expanded(
                      flex: 1,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Account'),
                                onPressed: () {
                                  // This is a bit of a hack to navigate, ideally we'd use named routes or a navigation service
                                  // For now, we just rely on the user switching tabs, but we could pop up a dialog here.
                                  // Let's just show a snackbar for now or redirect
                                  // Since we are inside a tab view, meaningful navigation is tricky without context of the main scaffold.
                                  // Simple solution: Show the relevant dialog directly? 
                                  // We can't easily reach into other screens' states.
                                  // Best approach: "Go to Accounts" creates a loose coupling but works.
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switch to Accounts tab to add account')));
                                },
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.monetization_on),
                                label: const Text('Add Income'),
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switch to Income tab to add income'))),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.money_off),
                                label: const Text('Add Expense'),
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switch to Outgoings tab to add expense'))),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '£${value.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
