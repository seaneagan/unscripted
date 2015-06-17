// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library args.src.usage;

import 'dart:math';

import '../../../unscripted.dart';
import '../../usage.dart';
import 'pens.dart';
import 'util.dart';

/**
 * Takes an [ArgParser] and generates a string of usage (i.e. help) text for its
 * defined options. Internally, it works like a tabular printer. The output is
 * divided into three horizontal columns, like so:
 *
 *     -h, --help  Prints the usage information
 *     |  |        |                                 |
 *
 * It builds the usage text up one column at a time and handles padding with
 * spaces and wrapping to the next line to keep the cells correctly lined up.
 */
class OptionHelp {
  static const numColumns = 3; // Abbreviation, long name, help.

  static const gutterWidth = 4; // Width of gutter between columns.

  /** The usage this is generating usage for. */
  final Usage usage;

  /** The working buffer for the generated usage text. */
  StringBuffer buffer;

  /**
   * The column that the "cursor" is currently on. If the next call to
   * [write()] is not for this column, it will correctly handle advancing to
   * the next column (and possibly the next row).
   */
  int currentColumn = 0;

  /** The width in characters of each column. */
  List<int> columnWidths;

  /** The formatters of each column. */
  List<Function> columnFormatters = [abbrFormatter, optionPen, helpFormatter];

  static String abbrFormatter(String help) {
    return help.splitMapJoin(
        ',',
        onMatch: (match) => textPen(match.group(0)),
        onNonMatch: optionPen);
  }

  static String helpFormatter(String help) {
    return help.splitMapJoin(
        new RegExp(r'<[^>]+>'),
        onMatch: (match) => optionPen(match.group(0)),
        onNonMatch: textPen);
  }

  /**
   * The number of sequential lines of text that have been written to the last
   * column (which shows help info). We track this so that help text that spans
   * multiple lines can be padded with a blank line after it for separation.
   * Meanwhile, sequential options with single-line help will be compacted next
   * to each other.
   */
  int numHelpLines = 0;

  /**
   * How many newlines need to be rendered before the next bit of text can be
   * written. We do this lazily so that the last bit of usage doesn't have
   * dangling newlines. We only write newlines right *before* we write some
   * real content.
   */
  int newlinesNeeded = 0;

  OptionHelp(this.usage);

  /**
   * Generates a string displaying usage information for the defined options.
   * This is basically the help text shown on the command line.
   */
  String generate() {
    buffer = new StringBuffer();

    calculateColumnWidths();

    usage.optionGroups.asMap().forEach((index, optionGroup) {
      if (optionGroup.hide != null && optionGroup.hide) return;

      var title = optionGroup.title != null
          ? getGroupTitle(optionGroup.title)
          : index == 0
              ? null
              : '_' * (columnWidths.fold(0, (prev, next) => prev + next) - gutterWidth);
      if (title != null) {
        if (buffer.isNotEmpty) buffer.write("\n");
        write(0, title, format: titlePen);
        newline();
        newline();
      }

      optionGroup.options.forEach((name, option) {
        if (option.hide != null && option.hide) return;

        write(0, getAbbreviation(option));
        write(1, getLongOption(name, option));

        var help = getHelp(option.help);
        if (help != null) {
          write(2, help);
        }

        if (option.allowed is Map) {
          var allowedValues = getAllowedValues(option).toList(growable: false);
          allowedValues.sort();
          newline();
          for (var name in allowedValues) {
            write(1, getAllowedTitle(name));
            write(2, option.allowed[name]);
          }
          newline();
        } else if (getAllowedValues(option) != null) {
          write(2, buildAllowedList(option));
        } else if (option.defaultsTo != null) {
          var defaultsTo = option is Flag && option.defaultsTo == true ?
              'on' :
              option is! Flag ? option.defaultsTo : null;
          if(defaultsTo != null) {
            write(2, '(defaults to "$defaultsTo")');
          }
        }

        // If any given option displays more than one line of text on the right
        // column (i.e. help, default value, allowed options, etc.) then put a
        // blank line after it. This gives space where it's useful while still
        // keeping simple one-line options clumped together.
        if (numHelpLines > 1) newline();
      });
    });

    return buffer.toString();
  }

  String getGroupTitle(String name) => '$name:';

  Iterable<String> getAllowedValues(Option option) {
    var allowed = option.allowed;
    if(allowed is Iterable) return allowed;
    if(allowed is Map) return allowed.keys;
    return null;
  }

  String getAbbreviation(Option option) {
    if (option.abbr != null) {
      return '-${option.abbr}, ';
    } else {
      return '';
    }
  }

  String getLongOption(String name, Option option) {
    var long = _getLongOption(name, option);
    return option.valueHelp == null ?
        long :
        '$long=<${option.valueHelp}>';
  }

  String _getLongOption(String name, Option option) {
    if (option is Flag && option.negatable) {
      return '--[no-]$name';
    } else {
      return '--$name';
    }
  }

  String getAllowedTitle(String allowed) {
    return '      [$allowed]';
  }

  void calculateColumnWidths() {
    int abbr = 0;
    int title = 0;
    usage.optionGroups.forEach((optionGroup) {
      if (optionGroup.hide != null && optionGroup.hide) return;

      // Make room for the group title.
      title = max(title, getGroupTitle(optionGroup.title).length);

      optionGroup.options.forEach((name, option) {
        // Make room in the first column if there are abbreviations.
        abbr = max(abbr, getAbbreviation(option).length);

        // Make room for the option.
        title = max(title, getLongOption(name, option).length);

        // Make room for the allowed help.
        if (option.allowed is Map) {
          for (var allowed in option.allowed.keys) {
            title = max(title, getAllowedTitle(allowed).length);
          }
        }
      });
    });

    // Leave a gutter between the columns.
    title += gutterWidth;
    columnWidths = [abbr, title];
  }

  void newline() {
    newlinesNeeded++;
    currentColumn = 0;
    numHelpLines = 0;
  }

  void write(int column, String text, {format(String)}) {
    var lines = text.split('\n');

    // Strip leading and trailing empty lines.
    while (lines.isNotEmpty && lines.first.trim() == '') {
      lines.removeAt(0);
    }

    while (lines.isNotEmpty && lines.last.trim() == '') {
      lines.removeLast();
    }

    for (var line in lines) {
      writeLine(column, line, format: format);
    }
  }

  void writeLine(int column, String text, {format(String)}) {
    // Write any pending newlines.
    while (newlinesNeeded > 0) {
      buffer.write('\n');
      newlinesNeeded--;
    }

    // Advance until we are at the right column (which may mean wrapping around
    // to the next line.
    while (currentColumn != column) {
      if (currentColumn < numColumns - 1) {
        buffer.write(' ' * columnWidths[currentColumn]);
      } else {
        buffer.write('\n');
      }
      currentColumn = (currentColumn + 1) % numColumns;
    }

    var formatter = format != null ? format : columnFormatters[column];

    var formatted = formatter(text);
    buffer.write(formatted);

    if (column < columnWidths.length) {
      // Fixed-size column, so pad it.
      buffer.write(' ' * (columnWidths[column] - text.length));
    }

    // Advance to the next column.
    currentColumn = (currentColumn + 1) % numColumns;

    // If we reached the last column, we need to wrap to the next line.
    if (column == numColumns - 1) newlinesNeeded++;

    // Keep track of how many consecutive lines we've written in the last
    // column.
    if (column == numColumns - 1) {
      numHelpLines++;
    } else {
      numHelpLines = 0;
    }
  }

  String buildAllowedList(Option option) {
    var allowedBuffer = new StringBuffer();
    allowedBuffer.write('[');
    bool first = true;
    var allowedValues = getAllowedValues(option);
    for (var allowed in allowedValues) {
      if (!first) allowedBuffer.write(', ');
      allowedBuffer.write(allowed);
      if (allowed == option.defaultsTo) {
        allowedBuffer.write(' (default)');
      }
      first = false;
    }
    allowedBuffer.write(']');
    return allowedBuffer.toString();
  }
}
