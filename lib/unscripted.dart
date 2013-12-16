
/// Design command line interfaces through normal programming interfaces
/// annotated with command line specific metadata.
library unscripted;

import 'dart:collection';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:unscripted/src/script_impl.dart';
import 'package:unscripted/src/util.dart';

part 'src/script.dart';
part 'src/annotations.dart';
part 'src/call_style.dart';
part 'src/usage.dart';
part 'src/usage_formatter.dart';
