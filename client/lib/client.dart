import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
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
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const App(),
    ),
  );
}