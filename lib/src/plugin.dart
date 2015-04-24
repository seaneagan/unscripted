
library unscripted.plugin;

import 'usage.dart';

class Plugin {

  const Plugin();

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

  bool onError(
      Usage usage,
      error,
      bool isWindows) {
    return true;
  }

}
