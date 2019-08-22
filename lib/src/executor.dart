import 'package:cryaml/src/expressions.dart';
import 'package:meta/meta.dart';

@immutable
class CrYAMLContext {
  final Map<String, dynamic> variables;

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

  eval(Expression variable) {}
}
