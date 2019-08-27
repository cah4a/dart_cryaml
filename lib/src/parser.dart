import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/nodes.dart';
import 'package:cryaml/src/token.dart';

class Parser {
  dynamic parse(Iterable<Token> tokens) {
    final iterator = _Iterator(tokens.iterator);
    final result = _parse(iterator);

    if (iterator.moveNext()) {
      throw FormatException("Found several CrYAML documents");
    }

    return result;
  }
}

dynamic _parse(_Iterator<Token> iterator, {bool until(Token)}) {
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

    CrYAMLNode document;
    List<CrYAMLDirectiveNode> children;

    if (iterator.hasNext() && iterator.next is IndentToken) {
      iterator.moveNext();
      document = _parse(iterator, until: (token) => token is DirectiveToken);

      while (iterator.current is DirectiveToken) {
        children ??= [];
        children.add(_parse(iterator));
      }

      if (iterator.current is DedentToken) {
        iterator.moveNext();
      } else {
        throw FormatException("Unexpected document");
      }
    }

    return CrYAMLDirectiveNode(
      token.name,
      token.arguments,
      document,
      children,
    );
  }

  if (token is KeyToken) {
    return CrYAMLMap(Map.fromEntries(_object(iterator, until: until)));
  }

  if (token is ListMarkToken) {
    return CrYAMLList(List.from(_array(iterator, until: until)));
  }

  throw FormatException("Unexpected token $token");
}

Iterable<MapEntry<String, dynamic>> _object(
  _Iterator<Token> iterator, {
  bool until(Token token),
}) sync* {
  while (iterator.moveNext()) {
    final keyToken = iterator.current;

    if (keyToken is DedentToken) {
      return;
    }

    if (keyToken is! KeyToken) {
      throw FormatException(
          "Only one document allowed here. Did you forgot colon earlier?");
    }

    final key = (keyToken as KeyToken).name;

    if (!iterator.hasNext() || (until != null && until(iterator.next))) {
      yield MapEntry(key, Expression.NULL);
      return;
    }

    final valueToken = iterator.next;

    if (valueToken is IndentToken) {
      iterator.moveNext();
      yield MapEntry(
        key,
        _parse(iterator),
      );
    } else if (valueToken is ExpressionToken) {
      iterator.moveNext();
      yield MapEntry(key, valueToken.expression);
    } else if (valueToken is KeyToken) {
      yield MapEntry(key, Expression.NULL);
    } else {
      throw FormatException("Unexpected token $valueToken");
    }

    if (until != null && iterator.hasNext() && until(iterator.next)) {
      return;
    }
  }
}

Iterable _array(_Iterator<Token> iterator, {bool until(Token)}) sync* {
  while (iterator.moveNext()) {
    if (iterator.current is DedentToken) {
      return;
    }

    if (iterator.current is! ListMarkToken) {
      throw FormatException("While parsing a block collection, expected '-'");
    }

    if (!iterator.hasNext() || iterator.next is ListMarkToken) {
      yield Expression.NULL;
    } else {
      yield _parse(
        iterator,
        until: (token) => token is ListMarkToken,
      );
    }

    if (until != null && iterator.hasNext() && until(iterator.next)) {
      return;
    }
  }
}

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
