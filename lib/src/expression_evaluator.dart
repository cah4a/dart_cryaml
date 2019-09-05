import 'package:cryaml/src/expressions.dart';

typedef dynamic ExpressionEvaluator(Expression expression);

ExpressionEvaluator createExpressionEvaluator(
  Map<String, Function> functions,
  Map<String, dynamic> variables,
) {
  ExpressionEvaluator eval;

  eval = (Expression expression) {
    if (expression is LiteralExpression) {
      return expression.value;
    }

    if (expression is VarExpression) {
      return variables[expression.name];
    }

    if (expression is CallExpression) {
      return Function.apply(
        functions[expression.name],
        expression.positionalArguments?.map(eval)?.toList(),
        expression.namedArguments?.map(
          (key, val) => MapEntry(Symbol(key), eval(val)),
        ),
      );
    }

    if (expression is ArrayExpression) {
      return expression.children.map(eval).toList();
    }

    if (expression is InterpolateExpression) {
      return expression.expressions.map(eval).join();
    }

    if (expression is BinaryExpression) {
      final left = eval(expression.left);
      final right = eval(expression.right);

      switch (expression.operation) {
        case '*':
          return left * right;
        case '/':
          return left / right;
        case '~/':
          return left ~/ right;
        case '%':
          return left % right;
        case '+':
          return left + right;
        case '-':
          return left - right;
        case '<<':
          return left << right;
        case '>>':
          return left >> right;
        case '<':
          return left < right;
        case '<=':
          return left <= right;
        case '>':
          return left > right;
        case '>=':
          return left >= right;
        case '==':
          return left == right;
        case '!=':
          return left != right;
        case '&':
          return left & right;
        case '^':
          return left ^ right;
        case '|':
          return left | right;
        case '&&':
          return left && right;
        case '||':
          return left || right;
      }
    }
  };

  return eval;
}
