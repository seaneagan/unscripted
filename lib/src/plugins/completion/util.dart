
library unscripted.plugins.completion.util;

String unescape(String w) {
  if (w.startsWith('"')) return w.replaceAll(new RegExp(r'^"|"$'), "");
  return w.replaceAll(new RegExp(r'\\ '), " ");
}

String escape(String w) {
  if (!new RegExp(r'\s+').hasMatch(w)) return w;
  return '"$w"';
}
