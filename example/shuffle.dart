
import 'dart:math';

import 'package:unscripted/unscripted.dart';

main(arguments) => declare(shuffle).execute(arguments);

@Command(help: 'Shuffles a list of numbers')
@ArgExample('7 1.4 2', help: 'might output "1.4 2 7"')
shuffle(
    @Rest(parser: num.parse, help: "Numbers to shuffle")
    List<num> numbers,
    {@Option(parser: int.parse, help: "Seed for the random number generator.")
     int seed
    }) =>
    print((numbers.toList()..shuffle(new Random(seed))).join(' '));
