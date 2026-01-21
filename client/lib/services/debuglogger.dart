import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

final glog = Logger('client');

const logLevel = String.fromEnvironment(
  'LOG_LEVEL',
  defaultValue: 'INFO',
);

void setupClientLogging() {
  if (kReleaseMode) {
    Logger.root.level = Level.OFF;
  } else {
    Logger.root.level = Level.ALL;
  }

  Logger.root.onRecord.listen((r) {
    // Shows in browser console
    // Chrome DevTools, Cloud Shell preview, etc.
    print(
      '[${r.level.name}] ${r.loggerName}: ${r.message}',
    );
  });
}

// log to Docker via Nginx
Future<void> logTo(String message) async {
  try {
    final response = await http.post(
      Uri.parse('${Uri.base.origin}/log'),
      headers: {'Content-Type': 'text/plain',
      'X-Client-log': message},
      body: message,
    );

    glog.info(message);
    if (response.statusCode != 204) {
      print('logTo: Unexpected status code: ${response.statusCode}');
    }
  } catch (e) {
    print('logTo failed: $e');
  }
}