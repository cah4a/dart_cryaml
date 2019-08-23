import 'package:cryaml/src/exceptions.dart';
import 'package:cryaml/src/expression_evaluator.dart';
import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/nodes.dart';
import 'package:meta/meta.dart';

@immutable
class CrYAMLContext {
  final Map<String, dynamic> variables;

  ExpressionEvaluator _evaluator;

  CrYAMLContext(Map<String, dynamic> variables)
      : assert(variables != null),
        variables = Map.unmodifiable(variables);

  dynamic operator [](String name) => variables[name];

  CrYAMLContext withVariable<T>(String name, T value) {
    return CrYAMLContext({
      ...variables,
      name: value,
    });
  }

  ExpressionEvaluator get evaluator {
    if (_evaluator == null) {
      _evaluator = createExpressionEvaluator({}, variables);
    }

    return _evaluator;
  }

  eval(node) {
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
