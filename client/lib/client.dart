import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'services/theme_service.dart';

import 'providers/account_provider.dart';
import 'providers/income_provider.dart';
import 'providers/outgoing_provider.dart';
import 'providers/transfer_provider.dart';
import 'providers/simulation_provider.dart';
import 'providers/admin_provider.dart';
import 'core/constants.dart';
import 'services/debugLogger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupClientLogging();
  await logTo('server:$apiBase');
  await http.get(Uri.parse('${Uri.base.origin}/ping'));
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeService()), // Add ThemeService
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => OutgoingProvider()),
        ChangeNotifierProvider(create: (_) => TransferProvider()),
        ChangeNotifierProvider(create: (_) => SimulationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const App(),
    ),
  );
}