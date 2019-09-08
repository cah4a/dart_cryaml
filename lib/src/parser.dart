import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/nodes.dart';
import 'package:cryaml/src/token.dart';
import 'package:meta/meta.dart';

class Parser {
  dynamic parse(Iterable<Token> tokens, {String source}) {
    try {
      final iterator = tokens.iterator;
      _ParseContext current = _ValueContext(null);
      final root = current;

      while (iterator.moveNext()) {
        final token = iterator.current;
        current = current.parse(token);
      }

      while (current != null) {
        current = current.eof();
      }

      return root.create();
    } on _Exception catch (e) {
      e.source = source;
      rethrow;
    }
  }
}

abstract class _ParseContext {
  final _ParseContext parent;
  bool isFinalized = false;

  _ParseContext(this.parent);

  _ParseContext parse(Token token) {
    assert(!isFinalized);

    if (parent?.shouldFinalize(token, this) == true) {
      finalize();
      return parent.childFinalized(create()).parse(token);
    }

    if (token is IndentToken) {
      return meetIndent(token);
    }

    if (token is DedentToken) {
      return meetDedent(token);
    }

    if (token is ListMarkToken) {
      return meetListMark(token);
    }

    if (token is KeyToken) {
      return meetKey(token);
    }

    if (token is ExpressionToken) {
      return meetExpression(token);
    }

    if (token is DirectiveToken) {
      return meetDirective(token);
    }

    throw _Exception("Unsupported token $token", token);
  }

  _ParseContext meetIndent(IndentToken token) {
    throw _Exception("Unexpected indent", token);
  }

  _ParseContext meetDedent(DedentToken token) {
    throw _Exception("Unexpected dedent", token);
  }

  _ParseContext meetListMark(ListMarkToken token) {
    throw _Exception("Unexpected list mark", token);
  }

  _ParseContext meetExpression(ExpressionToken token) {
    throw _Exception("Unexpected expression", token);
  }

  _ParseContext meetKey(KeyToken token) {
    throw _Exception("Unexpected key", token);
  }

  _ParseContext meetDirective(DirectiveToken token) {
    throw _Exception("Unexpected directive", token);
  }

  bool shouldFinalize(Token token, _ParseContext child) => false;

  _ParseContext childFinalized(dynamic value) => this;

  _ParseContext eof() {
    finalize();
    return parent?.childFinalized(create());
  }

  @mustCallSuper
  void finalize() {
    assert(!isFinalized);
    isFinalized = true;
  }

  dynamic create() {
    assert(isFinalized);
    return _create();
  }

  dynamic _create();
}

class _ValueContext extends _ParseContext {
  _ParseContext delegate;

  _ValueContext(_ParseContext parent) : super(parent);

  @override
  _ParseContext meetExpression(ExpressionToken token) {
    return delegate = _ExpressionContext(token.expression, this);
  }

  @override
  _ParseContext meetKey(KeyToken token) {
    return delegate = _BlockContext(token.name, this);
  }

  @override
  _ParseContext meetListMark(ListMarkToken token) {
    return delegate = _ListContext(this);
  }

  @override
  _ParseContext meetDirective(DirectiveToken token) {
    return delegate = _DirectiveContext(
      token.name,
      token.arguments,
      this,
    );
  }

  _ParseContext meetIndent(IndentToken token) {
    throw _Exception("Unexpected indent", token);
  }

  _ParseContext meetDedent(DedentToken token) {
    throw _Exception("Unexpected dedent", token);
  }

  @override
  bool shouldFinalize(Token token, _ParseContext child) =>
      parent?.shouldFinalize(token, child);

  @override
  _ParseContext childFinalized(dynamic value) {
    finalize();
    return parent?.childFinalized(value);
  }

  @override
  _create() => delegate?.create();
}

class _ExpressionContext extends _ParseContext {
  final Expression value;

  _ExpressionContext(this.value, _ParseContext parent) : super(parent);

  _ParseContext meetIndent(IndentToken token) {
    throw _Exception("Unexpected token", token);
  }

  _ParseContext meetDedent(DedentToken token) {
    throw _Exception("Unexpected dedent", token);
  }

  _ParseContext meetListMark(ListMarkToken token) {
    throw _Exception("Unexpected list mark after expression", token);
  }

  _ParseContext meetExpression(ExpressionToken token) {
    throw _Exception("Found several expressions", token);
  }

  _ParseContext meetKey(KeyToken token) {
    throw _Exception("Unexpected key after end of expression", token);
  }

  _ParseContext meetDirective(DirectiveToken token) {
    throw _Exception("Unexpected directive after end of expression", token);
  }

  @override
  dynamic _create() => value;
}

class _BlockContext extends _ParseContext {
  String key;
  final data = <String, dynamic>{};

  _BlockContext(this.key, _ParseContext parent) : super(parent);

  @override
  _ParseContext meetKey(KeyToken token) {
    if (key != null) {
      data[key] = Expression.NULL;
    }
    key = token.name;
    return this;
  }

  @override
  _ParseContext meetIndent(IndentToken token) {
    if (key == null) {
      throw _Exception("Unexpected indent while parsing block", token);
    }

    return _ValueContext(this);
  }

  @override
  _ParseContext meetDedent(DedentToken token) {
    finalize();
    return parent.childFinalized(create());
  }

  @override
  _ParseContext meetDirective(DirectiveToken token) {
    if (key == null) {
      throw _Exception("Unexpected directive while parsing block", token);
    }

    return _DirectiveContext(token.name, token.arguments, this);
  }

  @override
  _ParseContext meetExpression(ExpressionToken token) {
    if (key == null) {
      throw _Exception("Unexpected expression while parsing block", token);
    }

    data[key] = token.expression;
    key = null;
    return this;
  }

  _ParseContext meetListMark(ListMarkToken token) {
    throw _Exception(
      "Expected a key while parsing a block mapping.",
      token,
    );
  }

  @override
  _ParseContext childFinalized(dynamic value) {
    data[key] = value ?? Expression.NULL;
    key = null;
    return this;
  }

  @override
  void finalize() {
    if (key != null) {
      data[key] = Expression.NULL;
    }
    super.finalize();
  }

  @override
  _create() => CrYAMLMap(data);
}

class _ListContext extends _ParseContext {
  final data = [];
  bool mark = true;

  _ListContext(_ParseContext parent) : super(parent);

  @override
  _ParseContext meetListMark(ListMarkToken token) {
    if (mark) {
      data.add(Expression.NULL);
    }

    mark = true;
    return this;
  }

  @override
  _ParseContext meetKey(KeyToken token) {
    if (!mark) {
      throw _Exception("While parsing a block collection, expected '-'", token);
    }

    return _BlockContext(token.name, this);
  }

  @override
  _ParseContext meetExpression(ExpressionToken token) {
    mark = false;
    data.add(token.expression);
    return this;
  }

  @override
  _ParseContext meetDedent(DedentToken token) {
    finalize();
    return parent.childFinalized(create());
  }

  @override
  _ParseContext meetIndent(IndentToken token) {
    return _ValueContext(this);
  }

  @override
  _ParseContext meetDirective(DirectiveToken token) {
    if (!mark) {
      throw new _Exception("Unexpected directive while parsing list", token);
    }

    return _DirectiveContext(token.name, token.arguments, this);
  }

  @override
  bool shouldFinalize(Token token, _ParseContext child) {
    return token is ListMarkToken;
  }

  @override
  _ParseContext childFinalized(result) {
    mark = false;
    data.add(result);
    return this;
  }

  @override
  void finalize() {
    if (mark) {
      data.add(Expression.NULL);
      mark = false;
    }
    super.finalize();
  }

  @override
  _create() => CrYAMLList(data);
}

class _DirectiveContext extends _ParseContext {
  final String name;
  final List arguments;
  var document;
  List<CrYAMLDirectiveNode> children;

  bool hasBody = false;

  _DirectiveContext(this.name, this.arguments, _ParseContext parent)
      : super(parent);

  @override
  _ParseContext parse(Token token) {
    if (hasBody) {
      if (token is DirectiveToken) {
        return _DirectiveContext(token.name, token.arguments, this);
      }

      if (token is DedentToken) {
        finalize();
        return parent.childFinalized(create());
      }

      if (document == null) {
        return _ValueContext(this).parse(token);
      } else {
        throw _Exception("Found several documents in directive", token);
      }
    }

    if (token is IndentToken) {
      hasBody = true;
      return this;
    }

    // oneliner
    finalize();
    return parent.childFinalized(create()).parse(token);
  }

  @override
  bool shouldFinalize(Token token, _ParseContext child) {
    return token is DedentToken || token is DirectiveToken;
  }

  @override
  _ParseContext childFinalized(dynamic value) {
    if (value is CrYAMLDirectiveNode) {
      children ??= [];
      children.add(value);
    } else {
      document = value;
    }

    return this;
  }

  @override
  CrYAMLDirectiveNode _create() => CrYAMLDirectiveNode(
        name,
        arguments,
        document,
        children != null ? CrYAMLList(children) : null,
      );
}

class _Exception extends FormatException {
  final Token token;
  final String message;
  String source;

  int get offset => token.pos;

  _Exception(this.message, this.token) : super(message);
}
