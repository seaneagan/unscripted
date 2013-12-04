
part of ink;

const String _HELP = 'help';

Rest _getRestFromMethod(MethodMirror method) {
  var firstParameter = method.parameters.firstWhere(
      (parameter) => !parameter.isOptional,
      orElse: () => null);
  if(firstParameter != null) {
    return _getFirstMetadataMatch(firstParameter,
        (metadata) => metadata is Rest);
  }
    return null;
}

Usage _getUsageFromFunction(MethodMirror methodMirror, {Usage usage}) {

  if(usage == null) usage = new Usage();

  usage.rest = _getRestFromMethod(methodMirror);

  _addCommandMetadata(usage, methodMirror);

  var parameters = methodMirror.parameters;

  parameters.where((parameter) => parameter.isNamed).forEach((parameter) {

    _Arg arg;
    var type = parameter.type;
    var defaultValue;

    if(type == reflectClass(String)) {
      arg = new Option();
    } else if(type == reflectClass(bool)) {
      arg = new Flag();
    }
    // TODO: handle List, List<String> as Options with allowMultiple = true.

    InstanceMirror argAnnotation = parameter.metadata.firstWhere((annotation) =>
        annotation.reflectee is _Arg, orElse: () => null);

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

    _addArgToParser(usage.parser, dashesToCamelCase.decode(name), defaultValue, arg);
  });

  return usage;
}

Usage _getUsageFromClass(Type theClass) {

  var classMirror = reflectClass(theClass);

  var unnamedConstructor = _getUnnamedConstructor(classMirror);

  var usage = _getUsageFromFunction(unnamedConstructor);

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
    var subCommandUsage = _getUsageFromFunction(
        methodMirror,
        usage: usage.addCommand(commandName));
    _addCommandMetadata(subCommandUsage, methodMirror);
  });

  var constructors = classMirror.declarations.values
      .where((d) => d is MethodMirror && d.isConstructor);

  return usage;
}

_addCommandMetadata(Usage usage, DeclarationMirror declaration) {
  Command command = _getFirstMetadataMatch(
      declaration, (metadata) => metadata is Command);
  var description = command == null ? '' : command.help;
  usage.description = description;
  Iterable<ArgExample> examples = declaration.metadata
      .map((annotation) => annotation.reflectee)
      .where((metadata) => metadata is ArgExample);
  examples.forEach((example) {
    usage.addExample(example);
  });
}

_getFirstMetadataMatch(DeclarationMirror declaration, bool match(metadata)) {
  return declaration.metadata
      .map((annotation) => annotation.reflectee)
        .firstWhere(match, orElse: () => null);
}

void _addArgToParser(ArgParser parser, String name, defaultValue, _Arg arg) {

  var parserMirror = reflect(parser);

  var namedParameters = {};

  InstanceMirror argMirror = reflect(arg);

  setNamedParameter(Symbol name) {
    var fieldValue = argMirror.getField(name).reflectee;

    if(fieldValue != null) {
      namedParameters[name] = fieldValue;
    }
  }

  mergeProperties(Type type) {
    reflectClass(type)
      .declarations
      .values
      .where((DeclarationMirror d) => d is MethodMirror && d.isGetter)
      .map((methodMirror) => methodMirror.simpleName)
      .forEach(setNamedParameter);
  }

  mergeProperties(_Arg);

  var suffix;

  if(arg is Option) {

    suffix = 'Option';

    mergeProperties(Option);
  }

  if(arg is Flag) {

    suffix = 'Flag';

    mergeProperties(Flag);
  }

  if(defaultValue != null) {
    namedParameters[#defaultsTo] = defaultValue;
  }

  var parserMethod = 'add$suffix';

  parserMirror.invoke(new Symbol(parserMethod), [name], namedParameters);
}

// Returns a List whose elements are the required argument count, and whether
// there is a Rest parameter.
List _getPositionalParameterInfo(MethodMirror methodMirror) {
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

_getRestParameterIndex(MethodMirror methodMirror) {
  var positionalParameterInfo = _getPositionalParameterInfo(methodMirror);
  return positionalParameterInfo[1] ?
      positionalParameterInfo[0] :
        null;
}

MethodMirror _getUnnamedConstructor(ClassMirror classMirror) {
  var constructors = classMirror.declarations.values
  .where((d) => d is MethodMirror && d.isConstructor);

  return constructors.firstWhere((constructor) =>
      constructor.constructorName == const Symbol(''), orElse: () => null);
}
