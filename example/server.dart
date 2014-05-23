#!/usr/bin/env dart

import 'dart:io';

import 'package:unscripted/unscripted.dart';
import 'package:path/path.dart' as path;

main(arguments) => declare(Server).execute(arguments, isWindows: false);

class Server {

  final String configPath;

  @Command(help: 'Manages a server', completion: true, callStyle: CallStyle.SHEBANG)
  Server({@Option(allowed: _getCurrentDirectoryFilenames) this.configPath: 'config.xml'});

  @SubCommand(help: 'Start the server')
  start({bool clean}) {
    print('''
Starting the server.
Config path: $configPath''');
  }

  @SubCommand(help: 'Stop the server')
  stop() {
    print('Stopping the server.');
  }

}

Iterable<String> _getCurrentDirectoryFilenames(String prefix) {
  return Directory.current.listSync()
      .where((fse) => fse is File)
      .map((fse) => path.basename(fse.path))
      .where((fileName) => fileName.startsWith(prefix));
}
