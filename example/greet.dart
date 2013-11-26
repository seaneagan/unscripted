#!/usr/bin/env dart

import 'package:ink/ink.dart';

main(arguments) => ink(greet).execute(arguments);

@Command(help: 'Outputs a greeting')
greet(@Rest(min: 1) who, {String salutation : 'Hello', bool exclaim : false}) {
  print('$salutation ${who.join(' ')}${exclaim ? '!' : ''}');
}