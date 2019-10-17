import 'package:collection/collection.dart';
import 'package:cryaml/cryaml.dart';
import 'package:cryaml/src/context.dart';
import 'package:cryaml/src/exceptions.dart';
import 'package:cryaml/src/expressions.dart';

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

class CrYAMLList<T> extends DelegatingList<T> implements CrYAMLNode {
  CrYAMLList(List<T> base) : super(base);

  @override
  List evaluate(CrYAMLContext context) {
    final result = [];

    for (final node in this) {
      if (node is CrYAMLDirectiveNode) {
        final value = context.eval(node);

        if (value is Iterable) {
          result.addAll(value);
        } else {
          result.add(value);
        }
      } else {
        result.add(context.eval(node));
      }
    }

    return result;
  }
}

typedef Eval<T> = T Function([CrYAMLContext context]);

class CrYAMLDirectiveNode implements CrYAMLNode {
  final String name;
  final List arguments;
  final dynamic document;
  final CrYAMLList<CrYAMLDirectiveNode> children;

  CrYAMLDirectiveNode(
    this.name,
    this.arguments,
    this.document,
    this.children,
  );

  dynamic _arg(CrYAMLContext context, DirectiveSpec spec, int index) {
    final type = spec.arguments[index];
    final argument = arguments[index];

    switch (type) {
      case ArgumentType.declaration:
        if (argument is VarExpression) {
          return argument.name;
        }
        throw CrYAMLEvaluateException(
            "Expected argument $index to be variable declaration for directive $name");
      case ArgumentType.expression:
        if (argument is Expression) {
          return context.eval(argument);
        }
        throw CrYAMLEvaluateException(
            "Expected argument $index to be expression for directive $name");
      case ArgumentType.keyword:
        if (argument is String) {
          return argument;
        }
        throw CrYAMLEvaluateException(
          "Expected argument $index to be keywoard for directive $name",
        );
    }
  }

  Eval<T> _eval<T>(CrYAMLContext ctx, node) =>
      ([CrYAMLContext context]) => (context ?? ctx).eval(node);

  @override
  dynamic evaluate(CrYAMLContext context) {
    assert(context.specification.directives.containsKey(name));

    final directive = context.specification.directives[name];
    final spec = directive.specification;
    final argumentsCount = arguments?.length ?? 0;

    if (argumentsCount != spec.arguments.length) {
      throw CrYAMLEvaluateException(
        "Expected ${spec.arguments.length} arguments "
        "for directive $name "
        "got $argumentsCount instead",
      );
    }

    final args = [
      context,
      ...Iterable.generate(
        spec.arguments.length,
        (index) => _arg(context, spec, index),
      )
    ];

    final named = <Symbol, dynamic>{};

    switch (spec.documentType) {
      case DocumentType.none:
        break;
      case DocumentType.list:
        named[const Symbol('document')] = _eval<List>(context, document);
        break;
      case DocumentType.map:
        named[const Symbol('document')] = _eval<Map>(context, document);
        break;
      case DocumentType.expression:
      case DocumentType.any:
        named[const Symbol('document')] = _eval(context, document);
        break;
    }

    switch (spec.childrenType) {
      case ChildrenType.list:
        named[const Symbol('children')] = _eval<List>(context, children);
        break;
      case ChildrenType.single:
        if (children == null || children.isEmpty) {
          named[const Symbol('child')] = () => null;
        } else {
          named[const Symbol('child')] = _eval(context, children.first);
        }
        break;
      case ChildrenType.none:
        break;
    }

    try {
      return Function.apply((directive as dynamic).call, args, named);
    } on NoSuchMethodError {
      final signature = _makeSignature(spec);

      throw CrYAMLEvaluateException(
        "${directive.runtimeType} should implement call($signature) method",
      );
    }
  }

  String _makeSignature(DirectiveSpec spec) {
    final signature = [
      "CrYAMLContext context",
      ...Iterable.generate(
        spec.arguments.length,
        (index) => "arg$index",
      )
    ];

    final named = [];

    switch (spec.documentType) {
      case DocumentType.map:
      case DocumentType.list:
      case DocumentType.expression:
      case DocumentType.any:
        named.add("document()");
        break;
      default:
    }

    switch (spec.childrenType) {
      case ChildrenType.single:
        named.add("child()");
        break;
      case ChildrenType.list:
        named.add("children()");
        break;
      default:
    }

    if (named.isNotEmpty) {
      signature.add("{" + named.join(", ") + "}");
    }

    return signature.join(", ");
  }
}
