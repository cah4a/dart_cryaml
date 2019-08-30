import 'package:collection/collection.dart';

import 'expressions.dart';

final listEquals = ListEquality().equals;
final mapEquals = MapEquality().equals;

abstract class Token {
  final int pos;

  static const indent = IndentToken();
  static const dedent = DedentToken();
  static const listMark = ListMarkToken();
  
  factory Token.number(num value) {
    if (value is double) {
      return Token.expr(LiteralExpression<double>(value));
    }

    return Token.expr(LiteralExpression<int>(value));
  }

  factory Token.string(String value) =>
      Token.expr(LiteralExpression<String>(value));

  factory Token.bool(bool value) => Token.expr(LiteralExpression<bool>(value));

  factory Token.key(String name) = KeyToken;

  factory Token.expr(Expression expression) = ExpressionToken;

  factory Token.directive(String name, List arguments) = DirectiveToken;
}

class IndentToken implements Token {
  final int pos = null;

  const IndentToken();

  String toString() => "indent";
}

class DedentToken implements Token {
  final int pos = null;

  const DedentToken();

  String toString() => "dedent";
}

class ListMarkToken implements Token {
  final int pos = null;

  const ListMarkToken();

  String toString() => "listMark";
}

class KeyToken implements Token {
  final int pos = null;
  final String name;

  KeyToken(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyToken &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  String toString() => 'key($name)';

  @override
  int get hashCode => name.hashCode;
}

class ExpressionToken implements Token {
  final int pos = null;
  final Expression expression;

  ExpressionToken(this.expression);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpressionToken &&
          runtimeType == other.runtimeType &&
          expression == other.expression;

  @override
  int get hashCode => expression.hashCode;

  @override
  String toString() => "exp($expression)";
}

class DirectiveToken implements Token {
  final int pos = null;
  final String name;
  final List arguments;

  DirectiveToken(this.name, this.arguments);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectiveToken &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          listEquals(arguments, other.arguments);

  @override
  String toString() => "directive($name, $arguments)";
}
