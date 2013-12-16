
import 'package:unscripted/unscripted.dart';

main(arguments) => improvise(greet).execute(arguments);

// Optional command-line metadata:
@Command(help: 'Outputs a greeting')
@ArgExample('--salutation Welcome --exclaim Bob', help: 'enthusiastic')
greet(
    @Rest(help: "Name(s) to greet")
    List<String> who, // A rest parameter, must be last positional.
    {String salutation : 'Hello', // An option, use `@Option(...)` for metadata.
     bool exclaim : false}) { // A flag, use `@Flag(...)` for metadata.

  print('$salutation ${who.join(' ')}${exclaim ? '!' : ''}');

}
