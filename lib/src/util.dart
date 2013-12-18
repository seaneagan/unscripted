
library unscripted.src.util;

import 'dart:mirrors';

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/string_codecs.dart';
import 'package:unscripted/src/usage.dart';

const String HELP = 'help';

/// A base class for script annotations which include help.
class Help {
  /// The help text to include for this part of the command line interface.
  final String help;

  const Help({this.help});
}

/// A base class for script argument annotations.
class Arg extends Help {
  final String abbr;

  const Arg({String help, this.abbr}) : super(help: help);
}

class BaseCommand extends Help {
  const BaseCommand({String help}) : super(help: help);
}

Rest getRestFromMethod(MethodMirror method) {
  var lastParameter = method.parameters.lastWhere(
      (parameter) => !parameter.isOptional,
      orElse: () => null);
  if(lastParameter != null) {
    Rest rest = getFirstMetadataMatch(lastParameter,
        (metadata) => metadata is Rest);
    if(rest != null  && rest.name == null) {
      rest = new Rest(
          min: rest.min,
          help: rest.help,
          name: getDefaultPositionalName(lastParameter.simpleName));
    }
    return rest;
  }
  return null;
}

getDefaultPositionalName(Symbol symbol) {
  return MirrorSystem.getName(symbol).toUpperCase();
}

Usage getUsageFromFunction(MethodMirror methodMirror, {Usage usage}) {

  if(usage == null) usage = new Usage();

  var rest = getRestFromMethod(methodMirror);
  if(rest != null) {
    if(rest.name == null) {

    }
    usage.rest = rest;
  }
  _addCommandMetadata(usage, methodMirror);

  var parameters = methodMirror.parameters;

  var required = parameters
      .where((parameter) => !parameter.isOptional).toList();
  if(usage.rest != null) required.removeLast();

  var positionals = required.map((parameter) {
    Positional positional = getFirstMetadataMatch(
        parameter, (metadata) => metadata is Positional);

    String positionalName = getDefaultPositionalName(parameter.simpleName);
    String positionalHelp;
    if(positional != null) {
      if(positional.name != null) {
        positionalName = positional.name;
      }
      positionalHelp = positional.help;
    }
    return new Positional(name: positionalName, help: positionalHelp);
  });

  positionals.forEach((positional) =>
      usage.addPositional(positional.name, help: positional.help));

  parameters.where((parameter) => parameter.isNamed).forEach((parameter) {

    Arg arg;
    var type = parameter.type;
    var defaultValue;

    if(type == reflectClass(String)) {
      arg = new Option();
    } else if(type == reflectClass(bool)) {
      arg = new Flag();
    }
    // TODO: handle List, List<String> as Options with allowMultiple = true.

    InstanceMirror argAnnotation = parameter.metadata.firstWhere((annotation) =>
        annotation.reflectee is Arg, orElse: () => null);

    if(argAnnotation != null) {
      arg = argAnnotation.reflectee;
    }

    var name = MirrorSystem.getName(parameter.simpleName);

    if(parameter.hasDefaultValue) {
      defaultValue = parameter.defaultValue.reflectee;
    }

    if(arg == null) {
      throw 'Parameter $name is not a Flag, Option, Rest, List, String, bool';
    }

    addArgToParser(usage.parser, dashesToCamelCase.decode(name), defaultValue, arg);
  });

  return usage;
}

Usage getUsageFromClass(Type theClass) {

  var classMirror = reflectClass(theClass);

  var unnamedConstructor = getUnnamedConstructor(classMirror);

  var usage = getUsageFromFunction(unnamedConstructor);

  // TODO: Include inherited methods, when supported by 'dart:mirrors'.
  var methods = classMirror.declarations.values
      .where((d) =>
          d is MethodMirror &&
          d.isRegularMethod &&
          !d.isStatic);

  Map<MethodMirror, SubCommand> subCommands = {};

  methods.forEach((methodMirror) {
    var subCommand = methodMirror.metadata
        .map((im) => im.reflectee)
        .firstWhere(
            (v) => v is SubCommand,
            orElse: () => null);

    if(subCommand != null) {
      subCommands[methodMirror] = subCommand;
    }
  });

  var commands = {};

  subCommands.forEach((methodMirror, subCommand) {
    var commandName = dashesToCamelCase
        .decode(MirrorSystem.getName(methodMirror.simpleName));
    var subCommandUsage = getUsageFromFunction(
        methodMirror,
        usage: usage.addCommand(commandName));
  });

  var constructors = classMirror.declarations.values
      .where((d) => d is MethodMirror && d.isConstructor);

  return usage;
}

_addCommandMetadata(Usage usage, DeclarationMirror declaration) {
  BaseCommand command = getFirstMetadataMatch(
      declaration, (metadata) => metadata is BaseCommand);
  var description = command == null ? '' : command.help;
  usage.description = description;
  Iterable<ArgExample> examples = declaration.metadata
      .map((annotation) => annotation.reflectee)
      .where((metadata) => metadata is ArgExample);
  examples.forEach((example) {
    usage.addExample(example);
  });
}

getFirstMetadataMatch(DeclarationMirror declaration, bool match(metadata)) {
  return declaration.metadata
      .map((annotation) => annotation.reflectee)
        .firstWhere(match, orElse: () => null);
}

void addArgToParser(ArgParser parser, String name, defaultValue, Arg arg) {

  var suffix;

  var props = {
    #abbr: arg.abbr,
    #help: arg.help,
    #defaultsTo: defaultValue
  };

  if(arg is Option) {
    suffix = 'Option';
    props.addAll({
      #allowed: arg.allowed,
      #allowedHelp: arg.allowedHelp,
      #allowMultiple: arg.allowMultiple,
      #hide: arg.hide,
    });
  }

  if(arg is Flag) {
    suffix = 'Flag';
    props.addAll({
      #negatable: arg.negatable
    });
  }

  var namedParameters = props.keys.fold({}, ((ret, prop) {
    var value = props[prop];
    if(value != null) {
      ret[prop] = value;
    }
    return ret;
  }));

  var parserMethod = 'add$suffix';

  reflect(parser).invoke(new Symbol(parserMethod), [name], namedParameters);
}

List<String> getHelpPath(ArgResults results) {
  var path = [];
  var subResults = results;
  while(true) {
    if(subResults.options.contains(HELP) && subResults[HELP]) return path;
    if(subResults.command == null) return null;
    if(subResults.command.name == HELP) {
      var helpCommand = subResults.command;
      if(helpCommand.rest.isNotEmpty) path.add(helpCommand.rest.first);
      return path;
    }
    subResults = subResults.command;
    path.add(subResults.name);
  }
  return path;
}

// Returns a List whose elements are the required argument count, and whether
// there is a Rest parameter.
List getPositionalParameterInfo(MethodMirror methodMirror) {
  var positionals = methodMirror.parameters.where((parameter) =>
      !parameter.isNamed);

  // TODO: Support optional positionals.
  if(positionals.any((positional) => positional.isOptional)) {
    throw new UnimplementedError('Cannot use optional positional parameters.');
  }
  var requiredPositionals =
      positionals.where((parameter) => !parameter.isOptional);

  var isRest = false;
  if(requiredPositionals.isNotEmpty) {

    var lastFuncPositional = requiredPositionals.last;

    var isRestAnnotated = lastFuncPositional.metadata
        .map((annotation) => annotation.reflectee)
        .any((metadata) => metadata is Rest);
    // TODO: How to check if the type is List or List<String> ?
    // var isList = lastFuncPositional.type == reflectClass(List);
    isRest = isRestAnnotated;// || isList;
  }

  return [requiredPositionals.length - (isRest ? 1 : 0), isRest];
}

getRestParameterIndex(MethodMirror methodMirror) {
  var positionalParameterInfo = getPositionalParameterInfo(methodMirror);
  return positionalParameterInfo[1] ?
      positionalParameterInfo[0] :
        null;
}

MethodMirror getUnnamedConstructor(ClassMirror classMirror) {
  var constructors = classMirror.declarations.values
  .where((d) => d is MethodMirror && d.isConstructor);

  return constructors.firstWhere((constructor) =>
      constructor.constructorName == const Symbol(''), orElse: () => null);
}
