import 'package:unscripted/unscripted.dart';

main(arguments) => improvise(greet).execute(arguments);

@Command(help: 'Outputs a greeting')
@ArgExample('--salutation Welcome --exclaim Bob', help: 'enthusiastic')
greet(
    @Rest(help: "One or more names to greet, e.g. 'Jack' or 'Jack Jill'")
    List<String> who, // A "rest parameter.
    {String salutation : 'Hello', // An option.
     bool exclaim : false}) { // A flag.

  print('$salutation ${who.join(' ')}${exclaim ? '!' : ''}');

}
