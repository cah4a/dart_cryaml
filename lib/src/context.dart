import 'package:cryaml/cryaml.dart';
import 'package:cryaml/src/exceptions.dart';
import 'package:cryaml/src/expression_evaluator.dart';
import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/nodes.dart';

abstract class CrYAMLContext {
  Specification get specification;

  Map<String, dynamic> get variables;

  factory CrYAMLContext(
    Specification specification,
    Map<String, dynamic> variables,
  ) = _CrYAMLContext;

  dynamic eval(node);

  CrYAMLContext withVariable<T>(String name, T value);
}

class _CrYAMLContext implements CrYAMLContext {
  final Specification specification;
  final Map<String, dynamic> variables;

  ExpressionEvaluator _evaluator;

  _CrYAMLContext(this.specification, Map<String, dynamic> variables)
      : assert(variables != null),
        variables = Map.unmodifiable(variables);

  dynamic operator [](String name) => variables[name];

  CrYAMLContext withVariable<T>(String name, T value) =>
      _CrYAMLContext(specification, {
        ...variables,
        name: value,
      });

  ExpressionEvaluator get evaluator {
    if (_evaluator == null) {
      _evaluator = createExpressionEvaluator(
        specification.functions,
        variables,
      );
    }

    return _evaluator;
  }

  dynamic eval(node) {
    if (node is Expression) {
      return evaluator(node);
    }

    if (node is CrYAMLNode) {
      return node.evaluate(this);
    }

    if (node is VarExpression) {
      return variables[node.name];
    }

    throw new CrYAMLEvaluateException("Unknown node type ${node.runtimeType}");
  }
}
