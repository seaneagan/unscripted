#!/usr/bin/env dart

import 'package:ink/ink.dart';

main(arguments) => ink(greet).execute(arguments);

@Command(help: 'Outputs a greeting')
@ArgExample('--exclaim --salutation Howdy John Doe', help: 'enthusiastic')
greet(@Rest(min: 1, help: '<names>') who, {String salutation : 'Hello', bool exclaim : false}) {
  print('$salutation ${who.join(' ')}${exclaim ? '!' : ''}');
}
