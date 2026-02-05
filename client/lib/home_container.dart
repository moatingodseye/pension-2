import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/main_layout.dart';
import 'widgets/collapsible_sidebar.dart';
import 'providers/auth_provider.dart';
import 'services/theme_service.dart';
import 'services/csv_service.dart';
import 'providers/account_provider.dart';
import 'providers/income_provider.dart';
import 'providers/outgoing_provider.dart';
import 'providers/transfer_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/account_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/income_screen.dart';
import 'screens/outgoing_screen.dart';
import 'screens/simulation_screen.dart';
import 'screens/data_management_screen.dart';
import 'screens/admin_screen.dart';

// Import forms
import 'widgets/forms/account_form_dialog.dart';
import 'widgets/forms/income_form_dialog.dart';
import 'widgets/forms/outgoing_form_dialog.dart';
import 'widgets/forms/transfer_form_dialog.dart';

class HomeContainer extends StatefulWidget {
  const HomeContainer({super.key});

  @override
  State<HomeContainer> createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  int _selectedIndex = 0;
  bool _primaryCollapsed = true;
  bool _secondaryCollapsed = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _togglePrimary() {
    setState(() {
      _primaryCollapsed = !_primaryCollapsed;
    });
  }

  void _toggleSecondary() {
    setState(() {
      _secondaryCollapsed = !_secondaryCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeService = context.watch<ThemeService>();

    // Define Screens
    final screens = [
      const DashboardScreen(),       // 0
      const AccountScreen(),         // 1
      const IncomeScreen(),          // 2
      const OutgoingScreen(),        // 3
      const TransferScreen(),        // 4
      const SimulationScreen(),      // 5
      const DataManagementScreen(),  // 6
      const AdminScreen(),           // 7
    ];

    // Safe Index Logic
    int safeIndex = _selectedIndex;
    if (_selectedIndex == 7 && !auth.isAdmin) safeIndex = 0;

    // 1. Build Primary Sidebar Items
    final primaryItems = [
      SidebarItem(icon: Icons.dashboard, label: 'Dashboard'),
      SidebarItem(icon: Icons.account_balance, label: 'Accounts'),
      SidebarItem(icon: Icons.monetization_on, label: 'Incomes'),
      SidebarItem(icon: Icons.money_off, label: 'Outgoings'),
      SidebarItem(icon: Icons.compare_arrows, label: 'Transfers'),
      SidebarItem(icon: Icons.bar_chart, label: 'Sim'),
      SidebarItem(icon: Icons.storage, label: 'Data'),
      SidebarItem(icon: Icons.admin_panel_settings, label: 'Admin'),
      SidebarItem(
        icon: themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode, 
        label: themeService.isDarkMode ? 'Light Mode' : 'Dark Mode',
        onTap: themeService.toggleTheme,
      ),
      SidebarItem(
        icon: Icons.logout, 
        label: 'Logout', 
        onTap: () {
           auth.logout();
        }
      ),
    ];

    // 2. Build Secondary Sidebar Items
    List<SidebarItem> secondaryItems = [];
    String secondaryHeader = 'Actions';

    switch (safeIndex) {
      case 0: // Dashboard
        secondaryHeader = 'Quick Actions';
        secondaryItems = [
           SidebarItem(icon: Icons.add, label: 'Add New Account', onTap: () => _openDialog(const AccountFormDialog())),
           SidebarItem(icon: Icons.monetization_on, label: 'Add Income', onTap: () => _openDialog(const IncomeFormDialog())),
           SidebarItem(icon: Icons.money_off, label: 'Add Outgoing', onTap: () => _openDialog(const OutgoingFormDialog())),
           SidebarItem(icon: Icons.swap_horiz, label: 'Transfer', onTap: () => _openDialog(const TransferFormDialog())),

        ];
        break;
      case 1: // Accounts
        secondaryHeader = 'Account Actions';
        secondaryItems = [
          SidebarItem(icon: Icons.add, label: 'Add Account', onTap: () => _openDialog(const AccountFormDialog())),
          SidebarItem(icon: Icons.filter_list, label: 'Filter List', onTap: () => _placeholderAction('Filter Accounts')),
        ];
        break;
      case 2: // Incomes
        secondaryHeader = 'Income Actions';
        secondaryItems = [
          SidebarItem(icon: Icons.add, label: 'Add Income', onTap: () => _openDialog(const IncomeFormDialog())),
        ];
        break;
      case 3: // Outgoings
        secondaryHeader = 'Outgoing Actions';
        secondaryItems = [
          SidebarItem(icon: Icons.add, label: 'Add Outgoing', onTap: () => _openDialog(const OutgoingFormDialog())),
        ];
        break;
      case 4: // Transfers
         secondaryHeader = 'Transfer Actions';
         secondaryItems = [
           SidebarItem(icon: Icons.add, label: 'New Transfer', onTap: () => _openDialog(const TransferFormDialog())),
         ];
         break;
      case 6: // Data Management
        secondaryHeader = 'Data Actions';
        secondaryItems = [
          SidebarItem(icon: Icons.copy, label: 'Export Clipboard', onTap: () => _exportData(context, false)),
          SidebarItem(icon: Icons.save, label: 'Export File', onTap: () => _exportData(context, true)),
          SidebarItem(icon: Icons.upload_file, label: 'Import CSV', onTap: () => _importData(context)),
        ];
        break;
      case 7: // Admin
        secondaryHeader = 'Admin Actions';
        secondaryItems = [
          SidebarItem(icon: Icons.refresh, label: 'Reload Users', onTap: () {
             Provider.of<AdminProvider>(context, listen: false).loadUsers();
          }),
        ];
        break;
      default:
        secondaryHeader = 'Actions';
        secondaryItems = [
          SidebarItem(icon: Icons.help_outline, label: 'Help', onTap: () => _placeholderAction('Help')),
        ];
    }

    return MainLayout(
      primarySidebar: CollapsibleSidebar(
        items: primaryItems,
        selectedIndex: safeIndex,
        onItemSelected: _onItemTapped,
        isCollapsed: _primaryCollapsed,
        onToggle: _togglePrimary,
        header: const Row(children: [Icon(Icons.savings, color: Colors.blue), SizedBox(width: 8), Text('Pension', style: TextStyle(fontWeight: FontWeight.bold))]),
      ),
      secondarySidebar: CollapsibleSidebar(
        items: secondaryItems,
        selectedIndex: -1, 
        onItemSelected: (_) {}, 
        isCollapsed: _secondaryCollapsed,
        onToggle: _toggleSecondary,
        header: Text(secondaryHeader, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: screens[safeIndex],
    );
  }

  void _openDialog(Widget dialog) {
    showDialog(context: context, builder: (_) => dialog);
  }

  void _placeholderAction(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: $name (Coming Soon)')));
  }

  Future<void> _exportData(BuildContext context, bool useFile) async {
    // Implementation moved from DataManagementScreen
    final csvService = CsvService();
    final accProv = Provider.of<AccountProvider>(context, listen: false);
    final incProv = Provider.of<IncomeProvider>(context, listen: false);
    final outProv = Provider.of<OutgoingProvider>(context, listen: false);
    final transProv = Provider.of<TransferProvider>(context, listen: false);

    await Future.wait([
      accProv.load(),
      incProv.load(),
      outProv.load(),
      transProv.load(),
    ]);

    final accountsCsv = csvService.exportAccounts(accProv.accounts);
    final incomesCsv = csvService.exportIncomes(incProv.incomes);
    final outgoingsCsv = csvService.exportOutgoings(outProv.outgoings);
    final transfersCsv = csvService.exportTransfers(transProv.transfers);

    final allData = '== ACCOUNTS ==\n$accountsCsv\n\n'
        '== INCOMES ==\n$incomesCsv\n\n'
        '== OUTGOINGS ==\n$outgoingsCsv\n\n'
        '== TRANSFERS ==\n$transfersCsv';

    if (useFile) {
      await CsvService.saveAndExport(context, allData, 'pension_data_backup.txt');
    } else {
      await CsvService.copyToClipboard(context, allData);
    }
  }

  Future<void> _importData(BuildContext context) async {
      final content = await CsvService.pickAndRead(context);
      if (content == null) return;
      
      final csvService = CsvService();
      try {
          if (content.contains('== ACCOUNTS ==')) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bulk dump import not supported yet. Import individual CSVs.')));
              return;
          }
          
          bool imported = false;
          
          // Accounts
          if (content.contains('id,name,amount,type,date,rate') || (content.contains('name') && content.contains('amount') && content.contains('type'))) {
              final list = csvService.parseAccounts(content);
              if (list.isNotEmpty) {
                  final prov = Provider.of<AccountProvider>(context, listen: false);
                  for(var item in list) await prov.add(item);
                  imported = true;
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${list.length} Accounts')));
              }
          } 
          // Incomes
          else if (content.contains('intoAccount')) { 
              final list = csvService.parseIncomes(content);
              if (list.isNotEmpty) {
                  final prov = Provider.of<IncomeProvider>(context, listen: false);
                  for(var item in list) await prov.add(item);
                  imported = true;
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${list.length} Incomes')));
              }
          }
          // Outgoings
          else if (content.contains('fromAccount')) { 
              if (content.contains('intoAccount')) {
                    // Transfer
                    final list = csvService.parseTransfers(content);
                    if (list.isNotEmpty) {
                        final prov = Provider.of<TransferProvider>(context, listen: false);
                        for(var item in list) await prov.add(item);
                        imported = true;
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${list.length} Transfers')));
                    }
              } else {
                    // Outgoing
                    final list = csvService.parseOutgoings(content);
                    if (list.isNotEmpty) {
                        final prov = Provider.of<OutgoingProvider>(context, listen: false);
                        for(var item in list) await prov.add(item);
                        imported = true;
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${list.length} Outgoings')));
                    }
              }
          }
          
          if (!imported && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not identify CSV type or file empty.')));
          }

      } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Failed: $e')));
      }
  }
}
