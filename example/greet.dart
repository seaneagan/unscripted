#!/usr/bin/env dart

import 'package:unscripted/unscripted.dart';

main(arguments) => improvise(greet).execute(arguments);

@Command(help: 'Outputs a greeting')
@ArgExample('--exclaim --salutation Howdy Mr. John Doe', help: 'enthusiastic')
greet(
    String title,
    @Rest() who,
    {String salutation : 'Hello',
     bool exclaim : false}) {

  print('$salutation $title ${who.join(' ')}${exclaim ? '!' : ''}');

}
