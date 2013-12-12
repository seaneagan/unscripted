
library addable_list_view;

import 'dart:collection';

/// List view which allows only adding elements to the end.
class AddableListView<E> extends UnmodifiableListView<E> {

  List<E> _base;

  AddableListView(List<E> _base)
      : this._base = _base,
        super(_base);

  add(E item) => _base.add(item);
}
