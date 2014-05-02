
library command_line_test;

import 'package:unscripted/src/completion/completion.dart';
import 'package:unscripted/src/usage.dart';
import 'package:unittest/unittest.dart';

main() {

    var args = ['"a"', r'b\ b', 'c'];
    var compLine = args.join(' ');
    var cursor = compLine.length;
    var compPoint = cursor.toString();
    var argCount = args.length - 1;
    var compCWord = argCount.toString();

    makeCommandLine() => new CommandLine(args, environment: {
      'COMP_LINE' : compLine,
      'COMP_POINT': compPoint,
      'COMP_CWORD': compCWord
    });

    group('CommandLine', () {

      group('constructor', () {

        test('returns null if COMP_* not in environment', () {
          var it = new CommandLine(['"a"', 'b'], environment: {});
          expect(it, isNull);
        });

        test('extracts COMP_* from the environment', () {
          var it = makeCommandLine();
          expect(it.args, args.sublist(1));
          expect(it.line, compLine);
          expect(it.cursor, cursor);
          expect(it.wordIndex, argCount - 1);
        });

      });

      test('no args yields single empty word', () {
        var args = ['foo'];
        var line = args.map((a) => a + ' ').join();
        var it = new CommandLine(args, environment: {
          'COMP_LINE' : line,
          'COMP_POINT': line.length.toString(),
          'COMP_CWORD': args.length.toString()
        });
        expect(it.words, ['']);
      });

      test('words are unescaped', () {
        var it = makeCommandLine();
        expect(it.words, ['b b', 'c']);
      });

      test('word matches words at wordIndex', () {
        var it = makeCommandLine();
        expect(it.word, 'c');
      });

      test('partialLine matches words at wordIndex', () {
        var it = makeCommandLine();
        expect(it.partialLine, compLine);
      });

      test('partialWord matches word up to cursor', () {
        var it = makeCommandLine();
        expect(it.partialWord, 'c');
      });

      test('cursor at start of new word', () {
        var args = ['a', 'b', 'c'];
        var line = args.map((a) => a + ' ').join();
        var it = new CommandLine(args, environment: {
          'COMP_LINE' : line,
          'COMP_POINT': line.length.toString(),
          'COMP_CWORD': args.length.toString()
        });
        expect(it.word, '');
        expect(it.partialWord, '');
      });

    });

}
