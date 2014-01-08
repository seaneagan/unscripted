
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
     @Flag(negatable: false, abbr: 'T', help: 'display TAB characters as ^I')
     bool showTabs,
     @Flag(negatable: false, abbr: 'v', help: '(not yet supported) use ^ and M- notation, except for LFD and TAB')
     bool showNonprinting,
     @Flag(negatable: false, abbr: 'E', help: r'display $ at end of each line')
     bool showEnds}) {

  showEnds = showEnds || showAll;
  showTabs = showTabs || showAll;
  showNonprinting = showNonprinting || showAll;
  number = number || numberNonblank;

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

    if(showEnds) {
      lines = lines.map((line) => '$line\$');
    }

    if(showTabs) {
      lines = lines.map(showTabChars);
    }

    if(showNonprinting) {
      // TODO: Show non-printing characters.
    }

    lines.forEach(print);
  });
}

Stream<IndexedValue> enumerateStream(Stream stream) {
  int index = 0;
  return stream.transform(new StreamTransformer<dynamic, IndexedValue>.fromHandlers(
      handleData: (value, EventSink<IndexedValue> sink) {
        sink.add(new IndexedValue(index++, value));
      }));
}

Stream<IndexedValue> shiftForBlanks(Stream<IndexedValue> stream) {
  int blanks = 0;
  return stream.transform(new StreamTransformer<dynamic, IndexedValue>.fromHandlers(
      handleData: (IndexedValue value, EventSink<IndexedValue> sink) {
        var blank = value.value.isEmpty;
        if(blank) blanks++;
        sink.add(new IndexedValue(blank ? null : value.index - blanks, value.value));
      }));
}

Stream<String> squeezeBlankLines(Stream<String> stream) {
  bool lastBlank = false;
  return stream.transform(new StreamTransformer<String, String>.fromHandlers(
      handleData: (String value, EventSink<String> sink) {
        bool blank = value.isEmpty;
        if(lastBlank && blank) return;
        lastBlank = blank;
        sink.add(value);
      }));
}

String padInt(int i, {int length: 0, String pad: '0'}) {
  var str = i == null ? '' : i.toString();
  var padLength = length - str.length;
  return (padLength > 0) ?
      '${repeat(pad, padLength)}$str' :
      str;
}

String showTabChars(String str) => str.replaceAll('\t', '^I');
