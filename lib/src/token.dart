import 'package:collection/collection.dart';

import 'expressions.dart';

final listEquals = ListEquality().equals;
final mapEquals = MapEquality().equals;

abstract class Token {
  static const indent = IndentToken();
  static const dedent = DedentToken();
  static const listMark = ListMarkToken();

  factory Token.number(num value) {
    if (value is double) {
      return Token.expr(LiteralExpression<double>(value));
    }

    return Token.expr(LiteralExpression<int>(value));
  }

  factory Token.key(String name) = KeyToken;

  factory Token.expr(Expression expression) = ExpressionToken;

  factory Token.directive(String name, List<Expression> arguments) =
      DirectiveToken;
}

class IndentToken implements Token {
  const IndentToken();

  String toString() => "indent";
}

class DedentToken implements Token {
  const DedentToken();

  String toString() => "dedent";
}

class ListMarkToken implements Token {
  const ListMarkToken();

  String toString() => "listMark";
}

class KeyToken implements Token {
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

class StringToken implements Token {
  final String value;

  StringToken(this.value);

  @override
  String toString() => 'string($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringToken &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class NumberToken implements Token {
  final num value;

  NumberToken(this.value);

  @override
  String toString() => 'number($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringToken &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class ExpressionToken implements Token {
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
  final String name;
  final List<Expression> arguments;

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
