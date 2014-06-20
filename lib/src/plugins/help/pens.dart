
import 'package:ansicolor/ansicolor.dart';

AnsiPen namePen = new AnsiPen()..xterm(203);
AnsiPen titlePen = new AnsiPen()..white(bold: true);
AnsiPen commandPen = new AnsiPen()..yellow();
AnsiPen optionPen = new AnsiPen()..xterm(69);
AnsiPen positionalPen = new AnsiPen()..green();
AnsiPen textPen = new AnsiPen()..gray(level: 0.5);
AnsiPen errorPen = new AnsiPen()..red(bold: true);
