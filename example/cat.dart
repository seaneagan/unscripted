
library cat;

import 'dart:async';
import 'dart:convert';

import 'package:unscripted/unscripted.dart';
import 'package:quiver/iterables.dart';
import 'package:quiver/strings.dart';

main(arguments) => sketch(cat).execute(arguments);

@Command(help: 'Concatenate FILE(s), or standard input, to standard output.')
@ArgExample('f - g', help: "Output f's contents, then standard input, then g's contents.")
@ArgExample('', help: 'Copy standard input to standard output.')
cat(
    @Rest(min: 0, parser: Input.parse)
    List<Input> files,
    {@Flag(negatable: false, abbr: 'n', help: 'number all output lines')
     bool number,
     @Flag(negatable: false, abbr: 'b', help: 'number nonblank output lines')
     bool numberNonblank,
     @Flag(negatable: false, abbr: 's', help: 'never more than one single blank line')
     bool squeezeBlank,
     @Flag(negatable: false, abbr: 'A', help: 'equivalent to -vET')
     bool showAll,
     @Flag(negatable: false, abbr: 'e', help: 'equivalent to -vE')
     bool e,
     @Flag(negatable: false, abbr: 't', help: 'equivalent to -vT')
     bool t,
     @Flag(negatable: false, abbr: 'T', help: 'display TAB characters as ^I')
     bool showTabs,
     @Flag(negatable: false, abbr: 'E', help: r'display $ at end of each line')
     bool showEnds,
     @Flag(negatable: false, abbr: 'v', help: '(not yet supported) use ^ and M- notation, except for LFD and TAB')
     bool showNonprinting}) {

  if(showAll) showEnds = showTabs = showNonprinting = true;
  if(e)       showEnds            = showNonprinting = true;
  if(t)                  showTabs = showNonprinting = true;
  if(numberNonblank)                         number = true;

  if (files.isEmpty) {
    // Default to stdin.
    files = [Input.parse('-')];
  }

  files.forEach((Input input) {

    var lines = input.stream
        .transform(UTF8.decoder)
        .transform(const LineSplitter());

    if(squeezeBlank) {
      lines = squeezeBlankLines(lines);
    }

    if(number) {
      lines = enumerateStream(lines);
      if(numberNonblank) {
        lines = shiftForBlanks(lines);
      }
      lines = lines.map((IndexedValue pair) {
        var line = pair.value;
        var lineNumber = (numberNonblank && line.isEmpty) ? null : pair.index + 1;
        return '${padInt(lineNumber, length: 6, pad: ' ')}  $line';
      });
    }

    if(showEnds) lines = lines.map((line) => '$line\$');

    if(showTabs) lines = lines.map(showTabChars);

    // TODO: Show non-printing characters.
    if(showNonprinting) {}

    lines.forEach(print);
  });
}

Stream<IndexedValue> enumerateStream(Stream stream) {
  var index = 0;
  return stream.map((value) => new IndexedValue(index++, value));
}

Stream<IndexedValue> shiftForBlanks(Stream<IndexedValue> stream) {
  var blanks = 0;
  return stream.map((IndexedValue value) {
    var blank = value.value.isEmpty;
    if(blank) blanks++;
    return new IndexedValue(blank ? null : value.index - blanks, value.value);
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

String padInt(int i, {int length: 0, String pad: '0'}) {
  var str = i == null ? '' : i.toString();
  var padLength = length - str.length;
  return (padLength > 0) ?
      '${repeat(pad, padLength)}$str' :
      str;
}

String showTabChars(String str) => str.replaceAll('\t', '^I');
