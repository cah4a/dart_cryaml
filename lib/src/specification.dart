class Specification {
  const Specification({
    this.functions = const {},
    this.directives = const {},
  });

  final Map<String, Function> functions;

  final Map<String, Directive> directives;
}

enum ArgumentType {
  declaration,
  expression,
  keyword,
}

enum DocumentType {
  none,
  list,
  map,
  expression,
  any,
}

enum ChildrenType {
  none,
  single,
  list,
}

class DirectiveSpec {
  final List<ArgumentType> arguments;
  final DocumentType documentType;
  final ChildrenType childrenType;

  const DirectiveSpec({
    this.arguments = const [],
    this.documentType = DocumentType.none,
    this.childrenType = ChildrenType.none,
  })  : assert(arguments != null),
        assert(documentType != null),
        assert(childrenType != null);
}

abstract class Directive {
  final DirectiveSpec specification;

  const Directive([this.specification = const DirectiveSpec()]);
}
