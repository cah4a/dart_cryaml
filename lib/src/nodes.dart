import 'package:collection/collection.dart';
import 'package:cryaml/src/executor.dart';

abstract class CrYAMLNode {
  dynamic evaluate(CrYAMLContext context);
}

class CrYAMLMap extends DelegatingMap implements CrYAMLNode {
  CrYAMLMap(Map base) : super(base);

  @override
  Map<String, dynamic> evaluate(CrYAMLContext context) {
    return map((key, value) => MapEntry(key, context.eval(value)));
  }
}

class CrYAMLList extends DelegatingList implements CrYAMLNode {
  CrYAMLList(List base) : super(base);

  @override
  List evaluate(CrYAMLContext context) => map(context.eval).toList();
}

class CrYAMLDirectiveNode implements CrYAMLNode {
  final String node;
  final List arguments;
  final dynamic children;

  CrYAMLDirectiveNode(this.node, this.arguments, this.children);

  @override
  dynamic evaluate(CrYAMLContext context) {}
}
