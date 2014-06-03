
import 'plugins/all_tests.dart' as plugins;
import 'script_test.dart' as script;
import 'invocation_maker_test.dart' as invocation_maker;
import 'string_codecs_test.dart' as string_codecs;
import 'io_test.dart' as io;

main() {
  plugins.main();
  script.main();
  invocation_maker.main();
  string_codecs.main();
  io.main();
}
