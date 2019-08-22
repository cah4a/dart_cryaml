import 'executor.dart';
import 'expressions.dart';

class CrYAMLDeclarations {
  final List<CrYAMLDirective> directives;
  final Map<String, Function> functions;

  const CrYAMLDeclarations({this.directives, this.functions});
}

abstract class CrYAMLDirectiveArg<T> {}

const arg = _ArgsBuilder();

class _ArgsBuilder {
  const _ArgsBuilder();

  /// Load argument as a variable name
  ///
  /// @directive $foo -- will load "foo"
  CrYAMLDirectiveArg<String> declaration() => null;

  /// Load argument as string. Only provided variants are allowed
  ///
  /// @directive doThat -- will load string "doThat"
  CrYAMLDirectiveArg<String> oneOf(List<String> variants) => null;

  /// Load argument as expression
  ///
  /// @directive [1, 2, 3] -- will load [ArrayExpression]
  CrYAMLDirectiveArg<ArrayExpression> expression() => null;
}

abstract class CrYAMLDirective<T> {
  Map<String, CrYAMLDirectiveArg> get template;

  T execute(CrYAMLContext context, dynamic next(CrYAMLContext));
}

class ForDirective extends CrYAMLDirective<List> {
  final template = {
    "declare": arg.declaration(),
    "operation": arg.oneOf(["in"]),
    "from": arg.expression(),
  };

  List execute(
    CrYAMLContext context,
    dynamic next(CrYAMLContext), {
    String declare,
    List from,
  }) =>
      from.map((item) => next(context.withVariable(declare, item)));
}

class IfDirective extends CrYAMLDirective {
  final template = {
    "variable": arg.expression(),
    "operation": arg.oneOf(["in", "eq", "equal"]),
    "reference": arg.expression(),
  };

  @override
  dynamic execute(
    CrYAMLContext context,
    dynamic next(CrYAMLContext), {
    Expression variable,
    String operation,
    Expression reference,
  }) {
    final left = context.eval(variable);
    final right = context.eval(reference);

    bool isPositive = false;

    switch (operation) {
      case "in":
        isPositive = (right is List) && right.contains(left);
        break;
      case "eq":
      case "equal":
        isPositive = left == right;
        break;
    }

    if (isPositive) {
      return next(context);
    } else {
      return null;
    }
  }
}
