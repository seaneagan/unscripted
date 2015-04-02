
library io_test;

import 'dart:io';

import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/util.dart';
import 'package:mockable_filesystem/mock_filesystem.dart';
import 'package:test/test.dart';


main() {

  group('io', () {

//    setUp(() {
//      fileSystem = new MockFileSystem();
//    });

    group('Input', () {

      group('stdin', () {

        Input unit;

        setUp(() {
          unit = parseInput('-', fileSystem: fileSystem);
        });

        test('stream', () {
          expect(unit.stream, stdin);
        });

        test('path', () {
          expect(unit.path, isNull);
        });
      });

      group('file', () {

        Input unit;
        File file;

        setUp(() {
          file = fileSystem.getFile('foo.txt');
          file.writeAsStringSync('foo');
          unit = parseInput('foo.txt', fileSystem: fileSystem);
        });

        test('stream', () {
          expect(unit.stream.isEmpty, completion(isFalse));
        });

        test('path', () {
          expect(unit.path, endsWith('foo.txt'));
        });

        tearDown(() {
          return file.delete();
        });
      });
    });
    group('Output', () {

      group('stdin', () {

        Output unit;

        setUp(() {
          unit = parseOutput('-', fileSystem: fileSystem);
        });

        test('stream', () {
          expect(unit.sink, stdout);
        });

        test('path', () {
          expect(unit.path, isNull);
        });
      });

      group('file', () {

        Output unit;
        File file;

        setUp(() {
          file = fileSystem.getFile('foo.txt');
          file.writeAsStringSync('foo');
          unit = parseOutput('foo.txt', fileSystem: fileSystem);
        });

        test('sink', () {
          unit.sink.write('bar');
          return unit.sink.close().then((_) {
            expect(file.readAsStringSync(), 'bar');
          });
        });

        test('path', () {
          expect(unit.path, endsWith('foo.txt'));
        });

        tearDown(() {
          return file.delete();
        });
      });
    });
  });
}
