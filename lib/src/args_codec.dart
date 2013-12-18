
library args_codec;

import 'dart:convert';
import 'dart:mirrors';

import 'package:args/args.dart' show ArgResults;
import 'package:sequence_zip/sequence_zip.dart';
import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/invocation_maker.dart';
import 'package:unscripted/src/string_codecs.dart';
import 'package:unscripted/src/util.dart';

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

  final MethodMirror method;
  final Symbol memberName;

  ArgResultsToInvocationConverter(this.method, {this.memberName: #call});

  Invocation convert(ArgResults results) {

    var params = method.parameters;
    var positionalParams = params.where((param) => !param.isNamed);
    var positionalArgs = results.rest;
    var restParameterIndex = getRestParameterIndex(method);
    if(restParameterIndex == null) {
      var max = positionalParams.length;
      var actual = positionalArgs.length;
      if(actual > max){
        throw new StateError('Received $actual positional command line '
            'arguments, but only $max are allowed.');
      }
    } else {
      positionalParams = positionalParams.take(restParameterIndex).toList();
      positionalArgs = positionalArgs.take(restParameterIndex).toList();
    }

    Function getPositionalParser(ParameterMirror parameter) {
      Positional positional = getFirstMetadataMatch(parameter, (meta) => meta is Positional);
      if(positional != null) {
        return positional.parser;
      }
      return null;
    }

    var positionalParsers = positionalParams.map(getPositionalParser);

    parseArg(parser, String arg) {
      return parser == null ? arg : parser(arg);
    }

    List zipParsedArgs(args, parsers) {
      return new IterableZip(
          [args,
           parsers])
      .map((parts) => parseArg(parts[1], parts[0]))
        .toList();
    }

    var positionals = zipParsedArgs(positionalArgs, positionalParsers);
    if(restParameterIndex != null) {
      var rest = results.rest.skip(restParameterIndex);
      var restParser = getPositionalParser(params[restParameterIndex]);
      positionals.add(zipParsedArgs(rest, new Iterable.generate(rest.length, (_) => restParser)));
    }

    Map<Symbol, dynamic> named = results
        .options
        .where((option) => option != HELP)
        .fold({}, (result, option) {
          result[new Symbol(dashesToCamelCase.encode(option))] = results[option];
          return result;
        });

    method.parameters
        .where((parameter) => parameter.isNamed)
        .forEach((parameter) {
          Option option = getFirstMetadataMatch(parameter, (meta) => meta is Option);
          var arg = named[parameter.simpleName];
          if(option != null && option.parser != null && arg != null) {
            named[parameter.simpleName] = option.parser(arg);
          }
        });

    return new InvocationMaker.method(memberName, positionals, named).invocation;
  }
}
