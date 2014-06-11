
/// Design command line interfaces through normal programming interfaces
/// annotated with command line specific metadata.
library unscripted;

import 'dart:async';
import 'dart:io';

import 'package:unscripted/src/script_impl.dart';
import 'package:unscripted/src/util.dart';

export 'package:unscripted/src/plugins/completion/marker.dart';

part 'src/script.dart';
part 'src/annotations.dart';
part 'src/io.dart';
