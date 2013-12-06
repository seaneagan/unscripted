
part of unscripted;

class InvocationToArgsConverter extends Converter<Invocation, List<String>> {

  InvocationToArgsConverter();

  List<String> convert(Invocation input) {
    var positionals = input.positionalArguments.map((arg) => arg.toString());
    var named = input.namedArguments.keys.expand((option) {
      var value = input.namedArguments[option];
      var optionName = MirrorSystem.getName(option);

      var optionArg = '--$optionName';
      return value is bool ?
          [value ? optionArg : '--no-$optionName'] :
          [optionArg, value.toString()];
    });
    return [named, positionals].expand((x) => x);
  }
}

class ArgResultsToInvocationConverter extends Converter<ArgResults, Invocation> {

  final int _restParameterIndex;
  final Symbol memberName;

  ArgResultsToInvocationConverter(this._restParameterIndex, {this.memberName: #call});

  Invocation convert(ArgResults results) {

    var positionals = results.rest;

    if(_restParameterIndex != null) {
      positionals = positionals.sublist(0, _restParameterIndex)
          ..add(positionals.sublist(_restParameterIndex));
    }

    Map<Symbol, dynamic> named = results
        .options
        .where((option) => option != _HELP)
        .fold({}, (result, option) {
          result[new Symbol(dashesToCamelCase.encode(option))] = results[option];
          return result;
        });

    return new InvocationMaker.method(memberName, positionals, named).invocation;
  }
}
