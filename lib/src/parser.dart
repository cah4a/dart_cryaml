import 'package:cryaml/src/nodes.dart';
import 'package:cryaml/src/token.dart';

class Parser {
  dynamic parse(Iterable<Token> tokens) => _parse(
        _Iterator(tokens.iterator),
      );
}

dynamic _parse(_Iterator<Token> iterator) {
  if (!iterator.hasNext()) {
    return null;
  }

  final token = iterator.next;

  if (token is ExpressionToken) {
    iterator.moveNext();
    return token.expression;
  }

  if (token is DirectiveToken) {
    iterator.moveNext();
    return token;
  }

  if (token is KeyToken) {
    return CrYAMLMap(Map.fromEntries(_object(iterator)));
  }

  if (token is ListMarkToken) {
    return CrYAMLList(List.from(_array(iterator)));
  }

  throw FormatException("Unexpected token $token");
}

Iterable<MapEntry<String, dynamic>> _object(_Iterator<Token> iterator) sync* {
  while (iterator.moveNext()) {
    final keyToken = iterator.current;

    if (keyToken is DedentToken) {
      return;
    }

    final key = _keyToken(keyToken);

    if (!iterator.moveNext()) {
      yield MapEntry(key, null);
      return;
    }

    final valueToken = iterator.current;

    if (valueToken is IndentToken) {
      yield MapEntry(key, _parse(iterator));
    } else if (valueToken is ExpressionToken) {
      yield MapEntry(key, valueToken.expression);
    } else {
      throw FormatException("Unexpected token $valueToken");
    }

    if (iterator.hasNext() && iterator.next is ListMarkToken) {
      return;
    }
  }
}

String _keyToken(Token token) {
  if (token is KeyToken) {
    return token.name;
  }

  throw FormatException(
      "Only one document allowed here. Did you forgot colon earlier?");
}

Iterable _array(_Iterator<Token> iterator) sync* {
  while (iterator.moveNext()) {
    if (iterator.current is DedentToken) {
      return;
    }

    if (iterator.current is! ListMarkToken) {
      throw FormatException("While parsing a block collection, expected '-'");
    }

    yield _parse(iterator);
  }
}

typedef bool _Test<T>(T item);

class _Iterator<T> extends Iterator<T> {
  final Iterator<T> inner;
  T next;

  _Iterator(this.inner);

  @override
  T get current => next ?? inner.current;

  bool hasNext() {
    if (next != null) {
      return true;
    }

    if (!inner.moveNext()) {
      return false;
    }
    next = inner.current;
    return true;
  }

  @override
  bool moveNext() {
    if (next != null) {
      next = null;
      return true;
    }

    return inner.moveNext();
  }
}
