import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/tokenizer.dart';
import 'package:cryaml/src/token.dart';
import 'package:test/test.dart';

main() {
  final tokenizer = Tokenizer();

  group("simplest", () {
    test("empty", () {
      expectTokens(
        tokenizer.tokenize(""),
        [],
      );
    });

    test("only comment", () {
      expectTokens(
        tokenizer.tokenize("# empty line"),
        [],
      );
    });

    test("empty spaces", () {
      expectTokens(
        tokenizer.tokenize("  \n\n   \t"),
        [],
      );
    });

    test("int", () {
      expectTokens(
        tokenizer.tokenize("1"),
        [
          Token.number(1),
        ],
      );
    });

    test("double", () {
      expectTokens(
        tokenizer.tokenize("3.14"),
        [
          Token.number(3.14),
        ],
      );
    });

    test("string", () {
      expectTokens(
        tokenizer.tokenize('"foo"'),
        [
          Token.expr(LiteralExpression<String>("foo")),
        ],
      );
    });

    test("map key with comment", () {
      expectTokens(
        tokenizer.tokenize("foo: # empty line"),
        [Token.key("foo")],
      );

      expectTokens(
        tokenizer.tokenize("foo: # empty line\n  bar:"),
        [
          Token.key("foo"),
          Token.indent(20),
          Token.key("bar"),
          Token.dedent(24),
        ],
      );
    });

    test("consume indents", () {
      expectTokens(
        tokenizer.tokenize('\n\n    foo: "bar"'),
        [
          Token.key("foo"),
          Token.expr(LiteralExpression<String>("bar")),
        ],
      );
    });

    test("tabs are not allowed as indentation", () {
      expect(
        () => tokenizer.tokenize("\tfoo: 3"),
        throwsA(
          TypeMatcher<FormatException>().having((e) => e.message, "message",
              "Tab characters are not allowed as indentation."),
        ),
      );
    });
  });

  group("Identation", () {
    test("one level", () {
      final source = [
        'foo: "value"',
        'bar: "value"',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.key("foo"),
          Token.expr(LiteralExpression<String>("value")),
          Token.key("bar"),
          Token.expr(LiteralExpression<String>("value")),
        ],
      );
    });

    test("empty vals", () {
      final source = [
        'foo: ',
        'bar: "value"',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.key("foo"),
          Token.key("bar"),
          Token.expr(LiteralExpression<String>("value")),
        ],
      );
    });

    test("ignore empty lines and comments", () {
      final source = [
        '# start comment',
        '',
        'foo: "value" # other comments',
        '  ',
        '# comment',
        'bar: "value2"',
        '',
        '# end comment',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.key("foo"),
          Token.expr(LiteralExpression<String>("value")),
          Token.key("bar"),
          Token.expr(LiteralExpression<String>("value2")),
        ],
      );
    });

    test("one level indent", () {
      final source = [
        "key:",
        '    foo: "fooval"',
        '    bar: "barval"',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.key("key"),
          Token.indent(),
          Token.key("foo"),
          Token.expr(LiteralExpression<String>("fooval")),
          Token.key("bar"),
          Token.expr(LiteralExpression<String>("barval")),
          Token.dedent(),
        ],
      );
    });

    test("nested", () {
      final source = [
        "key:",
        '  foo:',
        '    bar: "barval"',
        '  baz: "bazval"',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.key("key"),
          Token.indent(),
          Token.key("foo"),
          Token.indent(),
          Token.key("bar"),
          Token.expr(LiteralExpression<String>("barval")),
          Token.dedent(),
          Token.key("baz"),
          Token.expr(LiteralExpression<String>("bazval")),
          Token.dedent(),
        ],
      );
    });

    test("wrong indent", () {
      final source = [
        "key:",
        '    foo:',
        '        bar: "barval"',
        '     baz: "bazval"',
      ].join("\n");

      expect(
        () => tokenizer.tokenize(source),
        throwsA(TypeMatcher<FormatException>()),
      );
    });
  });

  group("arrays", () {
    test("list of oneline objects", () {
      final source = [
        '- foo: 1',
        '- bar: 2',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.listMark(),
          Token.key("foo"),
          Token.number(1),
          Token.listMark(),
          Token.key("bar"),
          Token.number(2),
        ],
      );
    });

    test("list of strings with non filled values", () {
      final source = [
        '- "foo"',
        '- ',
        '- "bar"',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.listMark(),
          Token.expr(LiteralExpression<String>("foo")),
          Token.listMark(),
          Token.listMark(),
          Token.expr(LiteralExpression<String>("bar")),
        ],
      );
    });

    test("list of objects", () {
      final source = [
        '- key: "foo"',
        '  value: 1',
        '- key: "bar"',
        '  value: null',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.listMark(),
          Token.key("key"),
          Token.expr(LiteralExpression<String>("foo")),
          Token.key("value"),
          Token.number(1),
          Token.listMark(),
          Token.key("key"),
          Token.expr(LiteralExpression<String>("bar")),
          Token.key("value"),
          Token.expr(Expression.NULL),
        ],
      );
    });

    test("list as key value", () {
      final source = [
        'key:',
        '  - 1',
        '  - 2',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.key("key"),
          Token.indent(),
          Token.listMark(),
          Token.number(1),
          Token.listMark(),
          Token.number(2),
          Token.dedent(),
        ],
      );
    });

    test("complex list", () {
      final source = [
        'key:',
        '  - some: "foo"',
        '    other:',
        '    - "bar"',
        '',
        '  - kuz: "baz"'
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.key("key"),
          Token.indent(),
          Token.listMark(),
          Token.key("some"),
          Token.expr(LiteralExpression<String>("foo")),
          Token.key("other"),
          Token.indent(),
          Token.listMark(),
          Token.expr(LiteralExpression<String>("bar")),
          Token.dedent(),
          Token.listMark(),
          Token.key("kuz"),
          Token.expr(LiteralExpression<String>("baz")),
          Token.dedent(),
        ],
      );
    });
  });

  group("map", () {
    test("values types", () {
      final source = [
        'str: "string"',
        "int: 42",
        "double: 36.6",
        "null: null",
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.key("str"),
          Token.expr(LiteralExpression<String>("string")),
          Token.key("int"),
          Token.number(42),
          Token.key("double"),
          Token.number(36.6),
          Token.key("null"),
          Token.expr(Expression.NULL),
        ],
      );
    });
  });

  group("directives", () {
    test("oneliner", () {
      final source = ['@foobar'].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.directive("foobar", null),
        ],
      );
    });

    test("oneliners", () {
      final source = [
        '@foobar',
        '@foobar',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.directive("foobar", null),
          Token.directive("foobar", null),
        ],
      );
    });

    test("directive with body", () {
      final source = [
        '@foobar',
        '    nested: true',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.directive("foobar", null),
          Token.indent(),
          Token.key("nested"),
          Token.bool(true),
          Token.dedent(),
        ],
      );
    });

    test("directive as key with map body", () {
      final source = [
        'foobar: @foobar "foo"',
        '  nested: @foobar "other"',
        '  foo: 2',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.key("foobar"),
          Token.directive("foobar", [LiteralExpression("foo")]),
          Token.indent(),
          Token.key("nested"),
          Token.directive("foobar", [LiteralExpression("other")]),
          Token.key("foo"),
          Token.number(2),
          Token.dedent(),
        ],
      );
    });

    test("directive as key with list body", () {
      final source = [
        'foobar: @foobar "foo"',
        '  - true',
        '  - false',
        'other:'
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.key("foobar"),
          Token.directive("foobar", [LiteralExpression("foo")]),
          Token.indent(),
          Token.listMark(),
          Token.bool(true),
          Token.listMark(),
          Token.bool(false),
          Token.dedent(),
          Token.key("other"),
        ],
      );
    });

    test("directive with expressions", () {
      final source = ['@foobar 42'].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.directive("foobar", [
            LiteralExpression<int>(42),
          ]),
        ],
      );
    });

    test("directive with list of expressions", () {
      final source = [
        r'@foobar $var in [1, 2,',
        r'$foo + 5.0]',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.directive("foobar", [
            VarExpression("var"),
            "in",
            ArrayExpression([
              LiteralExpression<int>(1),
              LiteralExpression<int>(2),
              BinaryExpression(
                VarExpression("foo"),
                "+",
                LiteralExpression<double>(5.0),
              ),
            ]),
          ]),
        ],
      );
    });

    test("list of directives", () {
      final source = [
        r'- @foobar',
        r'- @foobar',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.listMark(0),
          Token.directive("foobar", null, 2),
          Token.listMark(10),
          Token.directive("foobar", null, 12),
        ],
      );
    });

    test("directive with nested directives", () {
      final source = [
        r'@foo $var',
        r'  key: 1',
        r'',
        r'  @something',
        r'  @something',
      ].join("\n");

      expectTokens(
        tokenizer.tokenize(source),
        [
          Token.directive("foo", [VarExpression("var")], 0),
          Token.indent(12),
          Token.key("key", 12),
          Token.number(1, 17),
          Token.directive("something", null, 22),
          Token.directive("something", null, 35),
          Token.dedent(45),
        ],
      );
    });
  });
}

expectTokens(source, List<Token> tokens) => expect(
      source,
      matchTokens(tokens),
    );

List<Matcher> matchTokens(List<Token> tokens) =>
    tokens.map(matchToken).toList();

Matcher matchToken(Token token) {
  if (token is KeyToken) {
    return MatchKeyToken(token);
  }
  if (token is ExpressionToken) {
    return MatchExpressionToken(token);
  }
  if (token is DirectiveToken) {
    return MatchDirectiveToken(token);
  }
  return MatchToken(token);
}

class MatchToken<T extends Token> extends Matcher {
  final T token;
  final matchers = <Matcher, Function>{};

  MatchToken(this.token) {
    matchers[equals(token.runtimeType)] = (token) => token.runtimeType;

    if (token.pos != null) {
      matchers[equals(token.pos)] = (Token token) => token.pos;
    }
  }

  @override
  bool matches(covariant Token item, Map matchState) {
    return matchers.keys.every(
      (matcher) => matcher.matches(matchers[matcher](item), matchState),
    );
  }

  @override
  Description describe(Description description) {
    return description.addDescriptionOf(token);
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    return matchers.keys.fold(
      mismatchDescription.add("Got").addDescriptionOf(item),
      (mismatchDescription, matcher) => matcher.describeMismatch(
            matchers[matcher](item),
            mismatchDescription,
            matchState,
            verbose,
          ),
    );
  }
}

class MatchKeyToken extends MatchToken<KeyToken> {
  MatchKeyToken(KeyToken token) : super(token) {
    matchers[equals(token.name)] = (KeyToken token) => token.name;
  }
}

class MatchExpressionToken extends MatchToken<ExpressionToken> {
  MatchExpressionToken(ExpressionToken token) : super(token) {
    matchers[equals(token.expression)] =
        (ExpressionToken token) => token.expression;
  }
}

class MatchDirectiveToken extends MatchToken<DirectiveToken> {
  MatchDirectiveToken(DirectiveToken token) : super(token) {
    matchers[equals(token.name)] = (DirectiveToken token) => token.name;
    matchers[equals(token.arguments)] =
        (DirectiveToken token) => token.arguments;
  }
}
