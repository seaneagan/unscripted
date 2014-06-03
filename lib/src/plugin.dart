
import 'package:unscripted/src/usage.dart';

class Plugin {

  updateUsage(Usage usage) {}

  bool onParse(
      Usage usage,
      CommandInvocation commandInvocation,
      Map<String, String> environment,
      bool isWindows) {
    return true;
  }

  bool onValidate(
      Usage usage,
      CommandInvocation commandInvocation,
      Map<String, String> environment,
      bool isWindows) {
    return true;
  }
}
