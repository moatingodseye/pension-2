import 'dart:io';
import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';
import 'package:shelf/shelf.dart';
import 'package:path/path.dart' as path;
import 'db.dart';
import 'debuglogger.dart';

final String tempPath = Platform.isWindows ? '' : '/tmp/';

Future<Response> backupHandler(Request request) async {
  try {
    Database db = pension.getDb();
    
    // Path for the backup file
//    final String path = '/tmp/backup.db'; // gcloud!
    final String backup = path.join(tempPath,'backup.db');
    
    // Open a backup database (this is where the backup will be saved)
    final backupFile = File(backup);

    try {
      if (backupFile.existsSync()) {
        backupFile.deleteSync();
      }
        
      db.execute("VACUUM INTO '$backup'");
    } catch (e) {
      glog.warning("Backup:$e");
    }

    // Read the backup file as bytes to send to the client
    final backupData = await backupFile.readAsBytes();

    // Send the backup file as a response to the client
    final headers = {
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': 'attachment; filename=backup_${DateTime.now().millisecondsSinceEpoch}.db',
    };

    return Response.ok(backupData, headers: headers);
  } catch (e) {
    return Response.internalServerError(body: 'Failed to backup database: $e');
  }
}

Future<Response> restoreHandler(Request request) async {
  // Check if the uploaded file has the correct type
  var contentType = request.headers['Content-Type'];

  if (contentType != 'application/octet-stream') {
    return Response.badRequest(body: 'Invalid file type. Expected application/octet-stream.');
  }

  try {
    // Read the uploaded file's data
    Database db = pension.getDb();
    final String liveDB = db.select('PRAGMA database_list;').first['file'];
    final String backup = path.join(tempPath,'restore.db');
    final uploadedFileData = await request.read().toList();
    final fileBytes = Uint8List.fromList(uploadedFileData.expand((i) => i).toList());

    // Write the received file to a temporary file
    final restoreFile = File(backup);
    await restoreFile.writeAsBytes(fileBytes);

    final restore = sqlite3.open(backup);
    try {
      pension.close();

      if (File(liveDB).existsSync()) {
        File(liveDB).deleteSync();
      }
      restore.execute("VACUUM INTO '$liveDB'");
    } finally {
      restore.dispose();
      pension.open();
    }

/*     try {
      db.execute("ATTACH DATABASE '$path' AS backup_db");
      try {
        final tables = db.select("select name FROM backup_db.sqlite_master WHERE type='table");
        for (final row in tables) {
          final name = row['name'];
          db.execute("DELETE FROM main.$name");
          db.execute("INSERT INTO main.$name SELECT * FROM backup_db.$name");
        }
        db.execute("COMMIT");
      } catch (e) {
        db.execute("ROLLBACK");
        rethrow;
      }
    } finally {
      db.execute("DETACH DATABASE backup_db");
    } */

    return Response.ok('Database restore successful!');
  } catch (e) {
    return Response.internalServerError(body: 'Failed to restore database: $e');
  }
}
