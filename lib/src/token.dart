import 'package:collection/collection.dart';

import 'expressions.dart';

final listEquals = ListEquality().equals;
final mapEquals = MapEquality().equals;

abstract class Token {
  final int pos;

  factory Token.indent([int position]) = IndentToken;

  factory Token.dedent([int position]) = DedentToken;

  factory Token.listMark([int position]) = ListMarkToken;

  factory Token.number(num value, [int position]) {
    if (value is double) {
      return Token.expr(LiteralExpression<double>(value), position);
    }

    return Token.expr(LiteralExpression<int>(value), position);
  }

  factory Token.string(String value, [int position]) =>
      Token.expr(LiteralExpression<String>(value), position);

  factory Token.bool(bool value, [int position]) =>
      Token.expr(LiteralExpression<bool>(value), position);

  factory Token.key(String name, [int position]) = KeyToken;

  factory Token.expr(Expression expression, [int position]) = ExpressionToken;

  factory Token.directive(String name, List arguments, [int position]) =
      DirectiveToken;
}

class IndentToken implements Token {
  final int pos;

  const IndentToken([this.pos]);

  String toString() => "indent" + (pos != null ? "[$pos]" : "");
}

class DedentToken implements Token {
  final int pos;

  const DedentToken([this.pos]);

  String toString() => "dedent" + (pos != null ? "[$pos]" : "");
}

class ListMarkToken implements Token {
  final int pos;

  const ListMarkToken([this.pos]);

  String toString() => "listMark" + (pos != null ? "[$pos]" : "");
}

class KeyToken implements Token {
  final int pos;
  final String name;

  KeyToken(this.name, [this.pos]);

  @override
  String toString() => 'key($name)' + (pos != null ? "[$pos]" : "");
}

class ExpressionToken implements Token {
  final int pos;
  final Expression expression;

  ExpressionToken(this.expression, [this.pos]);

  @override
  String toString() => "exp($expression)" + (pos != null ? "[$pos]" : "");
}

class DirectiveToken implements Token {
  final int pos;
  final String name;
  final List arguments;

  DirectiveToken(this.name, this.arguments, [this.pos]);

  @override
  String toString() =>
      "directive($name, $arguments)" + (pos != null ? "[$pos]" : "");
}
