
library unscripted.src.plugins.help.util;

import '../../util.dart';

String getHelp(h) {
  if (h == null) return null;
  if (h is Nullary) return h();
  return h;
}
