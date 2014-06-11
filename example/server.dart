#!/usr/bin/env dart

import 'dart:io';

import 'package:unscripted/unscripted.dart';
import 'package:path/path.dart' as path;

main(arguments) => declare(Server).execute(arguments);

class Server {

  final String configPath;

  @Command(
      help: 'Manages a server',
      plugins: const [const Completion()])
  Server({@Option(allowed: _getSamePrefixPaths) this.configPath: 'config.xml'});

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

Iterable<String> _getSamePrefixPaths(String p) {

  var dirname = path.basename(p).isEmpty ? p : path.dirname(p);
  var dir = new Directory(dirname);
  return dir.listSync()
      .map((fse) => path.basename(fse.path))
      .where((basename) => basename.startsWith(path.basename(p)))
      .map((basename) => path.join(dirname, basename));
}
