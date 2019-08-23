import 'dart:collection';

import 'package:cryaml/src/token.dart';

enum Indentation {
  indent,
  dedent,
  listIndent,
  unknown,
}

class Indentator {
  final _indents = Queue<_Indent>();
  _Indent _indent;

  Iterable<Indentation> call(int newIndent, int listMarkIndent) sync* {
    if (_indent == null) {
      _indent = _Indent(newIndent, listMarkIndent);
      _indents.addLast(_indent);
      if (listMarkIndent != null) {
        yield Indentation.listIndent;
      }
      return;
    }

    if (_indent.level == newIndent) {
      if (listMarkIndent != null) {
        yield Indentation.listIndent;
      }
      return;
    }

    if (listMarkIndent == null &&
        _indent.listLevel != null &&
        _indent.listLevel == newIndent) {
      return;
    }

    if (newIndent > _indent.level) {
      _indent = _Indent(newIndent, listMarkIndent);
      _indents.addLast(_indent);
      yield Indentation.indent;

      if (listMarkIndent != null) {
        yield Indentation.listIndent;
      }
      return;
    }

    while (newIndent < _indent.level && _indents.length > 1) {
      _indents.removeLast();
      _indent = _indents.last;
      yield Indentation.dedent;
    }

    if (listMarkIndent != null) {
      yield Indentation.listIndent;
    }

    if (newIndent > _indent.level) {
      yield Indentation.unknown;
    }
  }
}

class _Indent {
  final int level;
  final int listLevel;

  _Indent(this.level, [this.listLevel]);

  @override
  String toString() => '_Indent{level: $level, listLevel: $listLevel}';
}
