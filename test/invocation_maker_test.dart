
library invocation_maker_test;

import 'package:unscripted/src/invocation_maker.dart';
import 'package:unittest/unittest.dart';

main() {
  group('InvocationMaker', () {

    test('getter', () {
      var unit = new InvocationMaker.getter(#foo);
      var invocation = unit.invocation;
      expect(invocation.isGetter, isTrue);
      expect(invocation.memberName, #foo);
    });

    test('setter', () {
      var unit = new InvocationMaker.setter(#foo, 'foo');
      var invocation = unit.invocation;
      expect(invocation.isSetter, isTrue);
      expect(invocation.memberName, new Symbol('foo='));
      expect(invocation.positionalArguments.first, 'foo');
    });

    test('method', () {
      var positionals = ['foo'];
      var named = {#bar: 'baz'};
      var unit = new InvocationMaker.method(#foo, positionals, named);
      var invocation = unit.invocation;
      expect(invocation.isMethod, isTrue);
      expect(invocation.memberName, #foo);
      expect(invocation.positionalArguments, positionals);
      expect(invocation.namedArguments, named);
    });
  });
}
