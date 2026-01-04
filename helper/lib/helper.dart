import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

Future<void> backup(String url, String apiKey) async {
  final client = http.Client();
  try {
    await _backupDatabase(url, apiKey, client);
  } finally {
    client.close();
  }
}

Future<void> restore(String url, String apiKey, String from) async {
  final client = http.Client();
  try {
    await _restoreDatabase(url, apiKey, from, client);
  } finally {
    client.close();
  }
}

//final String tempPath = Platform.isWindows ? '' : '/tmp/';

Future<void> _backupDatabase(String url, String apiKey, http.Client client) async {
  final response = await client.post(
    Uri.parse('$url/backup'),
    headers: {
      'Authorization': 'Bearer $apiKey',
    },
  );

  if (response.statusCode == 200) {
    final backupFileName = 'backup.db';
    final backupData = response.bodyBytes;
    await File(backupFileName).writeAsBytes(backupData);
    print('Backup successful! File saved as: $backupFileName');
  } else {
    print('Failed to backup: ${response.body}');
  }
}

Future<void> _restoreDatabase(String url, String apiKey, String restorePath, http.Client client) async {
  final restoreFile = File(restorePath);
  final restoreData = await restoreFile.readAsBytes();

  final response = await client.post(
    Uri.parse('$url/restore'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/octet-stream',
    },
    body: restoreData,
  );

  if (response.statusCode == 200) {
    print('Restore successful: ${response.body}');
  } else {
    print('Failed to restore: ${response.body}');
  }
}
