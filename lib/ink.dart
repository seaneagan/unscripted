
/// Flip the (command line) script.
library ink;

import 'dart:collection';
import 'dart:convert';
import 'dart:mirrors';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:ink/src/invocation_maker.dart';
import 'package:ink/src/string_codecs.dart';

part 'src/script.dart';
part 'src/annotations.dart';
part 'src/call_style.dart';
part 'src/args_codec.dart';
part 'src/usage.dart';
part 'src/usage_format.dart';
part 'src/util.dart';
