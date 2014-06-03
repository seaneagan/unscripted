
Map<String, String> makeEnv(args) {
  var compLine = args.join(' ');
  var cursor = compLine.length;
  var compPoint = cursor.toString();
  var argCount = args.length - 2;
  var compCWord = argCount.toString();
  return {
    'COMP_LINE' : compLine,
    'COMP_POINT': compPoint,
    'COMP_CWORD': compCWord
  };
}
