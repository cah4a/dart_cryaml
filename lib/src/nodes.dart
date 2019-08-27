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
  final String name;
  final List arguments;
  final CrYAMLNode document;
  final List<CrYAMLDirectiveNode> children;

  CrYAMLDirectiveNode(
    this.name,
    this.arguments,
    this.document,
    this.children,
  );

  @override
  dynamic evaluate(CrYAMLContext context) {}
}
