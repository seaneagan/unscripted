#!/usr/bin/env dart

import 'package:unscripted/unscripted.dart';

main(arguments) => improvise(greet).execute(arguments);

@Command(help: 'Outputs a greeting')
@ArgExample('--exclaim --salutation Howdy Mr. John Doe', help: 'enthusiastic')
greet(
    @Positional(help: "such as 'Mr.' or 'Mrs.'")
    String title,
    @Rest(help: "One or more names to greet, e.g. 'Jack' or 'Jack Jill'")
    List<String> who,
    {String salutation : 'Hello',
     bool exclaim : false}) {

  print('$salutation $title ${who.join(' ')}${exclaim ? '!' : ''}');

}
