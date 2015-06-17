
library unscripted.tool.grind;

import 'dart:io';

import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task()
analyze() => new PubApp.global('tuneup').run(['check']);

@Task()
test() => new TestRunner().testAsync();

@Task()
coverage() {
  if (Platform.environment.containsKey('CI') &&
      Platform.environment['TRAVIS_DART_VERSION'] == 'stable') {

    var coverageTokenVar = 'COVERALLS_TOKEN';
    final String coverageToken = Platform.environment[coverageTokenVar];
    if (coverageToken == null) {
      log('Skipping, code coverage environment variable "$coverageTokenVar" is not defined.');
    }

    new PubApp.global('dart_coveralls').run(
      ['report',
       '--token', coverageToken,
       '--retry', '3',
       'test/all_tests.dart']);
  } else {
    // TODO: Run code coverage locally and output to console.
    //       Just skip uploading to coveralls.
    log('Skipping, code coverage is currently only run in CI.');
  }
}

@DefaultTask()
@Depends(analyze, test, coverage)
all() {}
