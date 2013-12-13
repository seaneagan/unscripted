#!/usr/bin/env dart

import 'package:unscripted/unscripted.dart';

main(arguments) => improvise(Server).execute(arguments);

@Command(help: 'Manages a server')
class Server {

  final String configPath;

  Server({this.configPath: 'config.xml'});

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
