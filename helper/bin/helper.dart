import 'package:helper/helper.dart' as helper;
import 'package:args/args.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('url', help: 'Cloud server URL', mandatory: true)
    ..addFlag('backup', help: 'Perform a backup', negatable: false)
    ..addFlag('restore', help: 'Perform a restore', negatable: false)
    ..addOption('restorePath', help: 'Path to restore file (for restore only)')
    ..addOption('apiKey', help: 'API Key for authentication', mandatory: true);

  final ArgResults argResults = parser.parse(arguments);

  final url = argResults['url'];
  final isBackup = argResults['backup'];
  final isRestore = argResults['restore'];
  final restorePath = argResults['restorePath'];
  final apiKey = argResults['apiKey'];

  if (!isBackup && !isRestore) {
    print('You must specify either --backup or --restore.');
    return;
  }

  if (isRestore && restorePath == null) {
    print('You must specify a --restorePath for restore.');
    return;
  }

  if (isBackup) {
    helper.backup(url,apiKey);
  }

  if (isRestore) {
    helper.restore(url,apiKey,restorePath);
  }
}
