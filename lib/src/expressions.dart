import 'utils.dart';

class Expression<T> {
  static const NULL = LiteralExpression<Null>(null);
  static const TRUE = LiteralExpression<bool>(true);
  static const FALSE = LiteralExpression<bool>(false);

  const Expression();
}

class LiteralExpression<T> extends Expression<T> {
  final T value;

  const LiteralExpression(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiteralExpression &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    if (value is String) {
      return '"$value"';
    }

    return "<$T>$value";
  }
}

class ArrayExpression extends Expression<List> {
  final List<Expression> children;

  ArrayExpression(this.children);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrayExpression &&
          runtimeType == other.runtimeType &&
          leq(children, other.children);

  @override
  int get hashCode => children.hashCode;

  @override
  String toString() => children.toString();
}

class VarExpression extends Expression {
  final String name;

  VarExpression(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VarExpression &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => "\$$name";
}

class CallExpression extends Expression {
  final String name;
  final List<Expression> positionalArguments;
  final Map<String, Expression> namedArguments;

  CallExpression(
    this.name, [
    this.positionalArguments,
    this.namedArguments,
  ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallExpression &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          leq(positionalArguments, other.positionalArguments) &&
          meq(namedArguments, other.namedArguments);

  @override
  int get hashCode =>
      name.hashCode ^ positionalArguments.hashCode ^ namedArguments.hashCode;

  @override
  String toString() {
    final args = <String>[];

    positionalArguments?.forEach(
      (expression) => args.add(expression.toString()),
    );

    namedArguments?.forEach((key, value) => args.add("$key: $value"));

    return "$name(${args.join(", ")})";
  }
}

class InterpolateExpression extends Expression {
  final List<Expression> expressions;

  InterpolateExpression(this.expressions);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpolateExpression &&
          runtimeType == other.runtimeType &&
          leq(expressions, other.expressions);

  @override
  int get hashCode => expressions.hashCode;

  @override
  String toString() => expressions.map(
        (expression) {
          if (expression is LiteralExpression) {
            return expression.value;
          }

          if (expression is VarExpression) {
            return expression;
          }

          return "#{$expression}";
        },
      ).join();
}

class BinaryExpression extends Expression {
  final Expression left;
  final String operation;
  final Expression right;

  BinaryExpression(this.left, this.operation, this.right);

  /// Operation and its order
  /// see [Order of operations](http://en.wikipedia.org/wiki/Order_of_operations#Programming_language)
  static final operations = {
    // Multiplication, division, modulo
    '*': 3, '/': 3, '~/': 3, '%': 3,
    // Addition and subtraction
    '+': 4, '-': 4,
    // Bitwise shift left and right
    '<<': 5, '>>': 5,
    // Comparisons: less-than and greater-than
    '<': 6, '<=': 6, '>': 6, '>=': 6,
    // Comparisons: equal and not equal
    '==': 7, '!=': 7,
    // Bitwise AND
    '&': 8,
    // Bitwise exclusive OR (XOR)
    '^': 9,
    // Bitwise inclusive (normal) OR
    '|': 10,
    // Logical AND
    '&&': 11,
    // Logical OR
    '||': 12,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BinaryExpression &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          operation == other.operation &&
          right == other.right;

  @override
  int get hashCode => left.hashCode ^ operation.hashCode ^ right.hashCode;

  @override
  String toString() {
    final l = left is BinaryExpression ? "($left)" : left;
    final r = right is BinaryExpression ? "($right)" : right;

    return "$l $operation $r";
  }
}

class GroupExpression extends Expression {
  final Expression child;

  GroupExpression(this.child);
}

class NegativeExpression extends Expression<bool> {
  final Expression child;

  NegativeExpression(this.child);
}
