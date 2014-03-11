
import 'dart:async';
import 'dart:convert';

import 'package:quiver/iterables.dart';
import 'package:quiver/streams.dart' as streams;
import 'package:quiver/strings.dart';
import 'package:unscripted/unscripted.dart';

main(arguments) => declare(cat).execute(arguments);

// TODO: Add tests, see https://gist.github.com/sandal/1293709
/// A dart implementation of the [cat][1] unix utility.
/// [1]: http://en.wikipedia.org/wiki/Cat_(Unix)
@Command(help: 'Concatenate FILE(s), or standard input, to standard output.')
@ArgExample('f - g', help: "Output f's contents, then standard input, then g's contents.")
@ArgExample('', help: 'Copy standard input to standard output.')
cat(
    List<Input> files,
    {@Flag(abbr: 'n', help: 'number all output lines')
     bool number,
     @Flag(abbr: 'b', help: 'number nonblank output lines')
     bool numberNonblank,
     @Flag(abbr: 's', help: 'never more than one single blank line')
     bool squeezeBlank,
     @Flag(abbr: 'A', help: 'equivalent to -vET')
     bool showAll,
     @Flag(abbr: 'e', help: 'equivalent to -vE')
     bool e,
     @Flag(abbr: 't', help: 'equivalent to -vT')
     bool t,
     @Flag(abbr: 'T', help: 'display TAB characters as ^I')
     bool showTabs,
     @Flag(abbr: 'E', help: r'display $ at end of each line')
     bool showEnds,
     @Flag(abbr: 'v', help: 'use ^ and M- notation, except for LFD and TAB')
     bool showNonprinting,
     @Flag(hide: true)
     bool version}) {

  // Placeholder: see https://github.com/seaneagan/unscripted/issues/21
  if(version) {
    print('cat.dart v0.1');
    return;
  }

  // Handle compound flags.
  if(showAll) showEnds = showTabs = showNonprinting = true;
  if(e)       showEnds            = showNonprinting = true;
  if(t)                  showTabs = showNonprinting = true;
  if(numberNonblank)                         number = true;

  // Default to stdin.
  if (files.isEmpty) files = [Input.parse('-')];

  // Get lines.
  var lines = streams.concat(files.map((Input input) =>
    input.stream.transform(UTF8.decoder.fuse(const LineSplitter()))));

  // Squeeze blank lines.
  if(squeezeBlank) lines = squeezeBlankLines(lines);

  // Number lines.
  if(number) {
    lines = streams.enumerate(lines);
    if(numberNonblank) {
      lines = shiftForBlanks(lines);
    }
    lines = lines.map((IndexedValue pair) {
      var line = pair.value;
      var lineNum = (numberNonblank && line.isEmpty) ? null : pair.index + 1;
      var lineNumString = lineNum == null ? '' : lineNum.toString();
      return '${padLeft(lineNumString, 6, ' ')}  $line';
    });
  }

  // Show non-printing characters.
  if(showEnds)        lines = lines.map((line) => '$line\$');
  if(showTabs)        lines = lines.map((str) => str.replaceAll('\t', '^I'));
  if(showNonprinting) lines = lines.map(showNonprintables);

  // Print lines.
  lines.forEach(print);
}

Stream<IndexedValue> shiftForBlanks(Stream<IndexedValue> stream) {
  var blanks = 0;
  return stream.map((IndexedValue pair) {
    var blank = pair.value.isEmpty;
    if(blank) blanks++;
    return new IndexedValue(blank ? null : pair.index - blanks, pair.value);
  });
}

Stream<String> squeezeBlankLines(Stream<String> stream) {
  var lastBlank = false;
  return stream.where((String value) {
    var blank = value.isEmpty;
    var squeeze = lastBlank && blank;
    lastBlank = blank;
    return !squeeze;
  });
}

// See http://docstore.mik.ua/orelly/unix3/upt/ch12_04.htm
String showNonprintables(String line) {
  String convertNonprintable(int char) {
    isControl(int char) => char <= 31 || char == 127;
    var buffer = new StringBuffer();
    if (char >= 128) {
      // TODO: I don't think these "metacharacters" are handled correctly yet.
      char &= 127;
      buffer.write('M-');
    }
    if (isControl(char)) {
      buffer.write('^');
      if (char == 127) {
        buffer.write('?');
      } else {
        buffer.writeCharCode(char + '@'.codeUnitAt(0));
      }
    } else {
      buffer.writeCharCode(char);
    }
    return buffer.toString();
  }

  var re = new RegExp(r'[\x00-\x08\x0A-\x1F\x7F]|[^\x00-\x7F]');
  return line.replaceAllMapped(re, (match) =>
      convertNonprintable(match.input.codeUnitAt(0)));
}
