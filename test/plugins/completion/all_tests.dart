

import 'command_line_test.dart' as command_line_test;
// import 'completion_command_test.dart' as completion_command_test;
import 'usage_completion_test.dart' as usage_completion_test;

main() {
  command_line_test.main();
  // TODO: Figure out how to do ene-to-end tests now that completion can be async.
  // completion_command_test.main();
  usage_completion_test.main();
}
