
// NOTE:  This is an example of how 'greet.dart' might be written *without*
// unscripted.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';

ArgParser parser;

main(arguments) {

  parser = new ArgParser()
      ..addOption('salutation', defaultsTo: 'Hello')
      ..addFlag('exclaim')
      ..addFlag('help', abbr: 'h');

  ArgResults results;

  try {
    results = parser.parse(arguments);
  } catch(e) {
    print(e);
    printHelp();
    return;
  }

  if(results['help']) {
    printHelp();
    return;
  }

  var who = results.rest;
  if(who.isEmpty){
    print("Must provide at least one name to greet.");
    printHelp();
    return;
  }

  greet(who, salutation: results['salutation'], exclaim: results['exclaim']);
}

greet(
    List<String> who,
    {String salutation,
     bool exclaim : false}) {

  print('$salutation ${who.join(' ')}${exclaim ? '!' : ''}');

}

printHelp() {

  var command = 'dart ${basename(Platform.script.path)}';

  print('''
Outputs a greeting

Usage:

$command [options] <WHO>'

Options:

${parser.getUsage()}

Examples:

$command --salutation Welcome --exclaim Bob # enthusiastic
''');
}
