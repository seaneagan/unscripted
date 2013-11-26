
import 'package:unittest/unittest.dart';
import 'package:ink/src/string_codecs.dart';

main() {

  group('SeparatorCodec', () {

    SeparatorCodec unit;

    setUp(() {
      unit = new SeparatorCodec(',', splitter: new RegExp(r'[ ,]'));
    });

    group('encode', () {

      test('empty', () {
        expect(unit.encode([]), '');
      });

      test('singleton', () {
        expect(unit.encode(['a']), 'a');
      });

      test('multiple', () {
        expect(unit.encode(['a', 'b']), 'a,b');
      });

    });

    group('decode', () {

      test('empty', () {
        expect(unit.decode(''), ['']);
      });

      test('singleton', () {
        expect(unit.decode('a'), ['a']);
      });

      test('multiple', () {
        expect(unit.decode('a b'), ['a', 'b']);
      });

    });
  });

  group('CamelCaseCodec', () {

    CamelCaseCodec unit;

    setUp(() {
      unit = new CamelCaseCodec(false);
    });

    group('encode', () {

      test('empty', () {
        expect(unit.encode([]), '');
      });

      test('singleton', () {
        expect(unit.encode(['A']), 'a');
      });

      test('multiple', () {
        expect(unit.encode(['ab', 'cd']), 'abCd');
      });

    });

    group('decode', () {

      test('empty', () {
        expect(unit.decode(''), []);
      });

      test('singleton', () {
        expect(unit.decode('a'), ['a']);
      });

      test('multiple', () {
        expect(unit.decode('ABc'), ['a', 'bc']);
      });

    });
  });
}
