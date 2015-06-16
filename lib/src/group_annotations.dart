
import '../unscripted.dart';
import 'util.dart';

class GroupMarker extends HelpAnnotation implements Group {

  final String title;
  final bool hide;

  const GroupMarker({
      this.title,
      help,
      this.hide})
      : super(help: help);
}

class StartGroup extends GroupMarker {
  const StartGroup({
    String title,
    help,
    bool hide}) : super(title: title, help: help, hide: hide);
}

class CombinedGroup extends GroupMarker {
  const CombinedGroup(
    this.getOptions,
    {String title,
     help,
     bool hide}) : super(title: title, help: help, hide: hide);

  /// Whether to hide this group.
  final Function getOptions;
}
