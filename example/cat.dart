
import 'dart:async';
import 'dart:convert';

import 'package:unscripted/unscripted.dart';
import 'package:quiver/async.dart';
import 'package:quiver/iterables.dart';
import 'package:quiver/strings.dart';

main(arguments) => sketch(cat).execute(arguments);

@Command(help: 'Concatenate FILE(s), or standard input, to standard output.')
@ArgExample('f - g', help: "Output f's contents, then standard input, then g's contents.")
@ArgExample('', help: 'Copy standard input to standard output.')
/// A dart implementation of the unix utility [cat][cat_wiki].
/// [cat_wiki]: http://en.wikipedia.org/wiki/Cat_(Unix)
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
     @Flag(abbr: 'v', help: '(not yet supported) use ^ and M- notation, except for LFD and TAB')
     bool showNonprinting}) {

  if(showAll) showEnds = showTabs = showNonprinting = true;
  if(e)       showEnds            = showNonprinting = true;
  if(t)                  showTabs = showNonprinting = true;
  if(numberNonblank)                         number = true;

  if (files.isEmpty) {
    // Default to stdin.
    files = [Input.parse('-')];
  } else {
    // TODO: If there are multiple stdin files ('-') does cat store the
    // stdin content for the later ones?
  }

  forEachAsync(files, (Input input) {

    var bytesToLines = UTF8.decoder.fuse(const LineSplitter());
    var lines = input.stream.transform(bytesToLines);

    if(squeezeBlank) lines = squeezeBlankLines(lines);

    if(number) {
      lines = enumerateStream(lines);
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

    if(showEnds) lines = lines.map((line) => '$line\$');

    if(showTabs) lines = lines.map((str) => str.replaceAll('\t', '^I'));

    // TODO: Show non-printing characters.
    // See http://docstore.mik.ua/orelly/unix3/upt/ch12_04.htm
    if(showNonprinting) {}

    return lines.forEach(print);
  });
}

Stream<IndexedValue> enumerateStream(Stream stream) {
  var index = 0;
  return stream.map((value) => new IndexedValue(index++, value));
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
