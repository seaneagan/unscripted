#!/usr/bin/env dart

import 'package:ink/ink.dart';

main(arguments) => ink(greet).execute(arguments);

@Command(help: 'Outputs a greeting')
@ArgExample('--exclaim --salutation Howdy Mr. John Doe', help: 'enthusiastic')
greet(String title, @Rest(min: 1, help: '<names>') who, {String salutation : 'Hello', bool exclaim : false}) {
  print('$salutation $title ${who.join(' ')}${exclaim ? '!' : ''}');
}
