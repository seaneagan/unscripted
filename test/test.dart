
import 'completion/test.dart' as completion_test;
import 'script_test.dart' as script_test;
import 'invocation_maker_test.dart' as invocation_maker_test;
import 'string_codecs_test.dart' as string_codecs_test;
import 'io_test.dart' as io_test;

main() {
  completion_test.main();
  script_test.main();
  invocation_maker_test.main();
  string_codecs_test.main();
  io_test.main();
}
