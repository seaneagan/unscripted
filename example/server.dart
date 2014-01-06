#!/usr/bin/env dart

import 'package:unscripted/unscripted.dart';

main(arguments) => sketch(Server).execute(arguments);

class Server {

  final String configPath;

  @Command(help: 'Manages a server')
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
