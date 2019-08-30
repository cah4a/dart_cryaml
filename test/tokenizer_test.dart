import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/tokenizer.dart';
import 'package:cryaml/src/token.dart';
import 'package:test/test.dart';

main() {
  final tokenizer = Tokenizer();

  group("simplest", () {
    test("empty", () {
      expect(
        tokenizer.tokenize(""),
        [],
      );
    });

    test("only comment", () {
      expect(
        tokenizer.tokenize("# empty line"),
        [],
      );
    });

    test("empty spaces", () {
      expect(
        tokenizer.tokenize("  \n\n   \t"),
        [],
      );
    });

    test("int", () {
      expect(
        tokenizer.tokenize("1"),
        [
          Token.number(1),
        ],
      );
    });

    test("double", () {
      expect(
        tokenizer.tokenize("3.14"),
        [
          Token.number(3.14),
        ],
      );
    });

    test("string", () {
      expect(
        tokenizer.tokenize('"foo"'),
        [
          Token.expr(LiteralExpression<String>("foo")),
        ],
      );
    });

    test("map key with comment", () {
      expect(
        tokenizer.tokenize("foo: # empty line"),
        [Token.key("foo")],
      );

      expect(
        tokenizer.tokenize("foo: # empty line\n  bar:"),
        [
          Token.key("foo"),
          Token.indent,
          Token.key("bar"),
          Token.dedent,
        ],
      );
    });

    test("consume indents", () {
      expect(
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

      expect(
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

      expect(
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

      expect(
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.key("key"),
          Token.indent,
          Token.key("foo"),
          Token.expr(LiteralExpression<String>("fooval")),
          Token.key("bar"),
          Token.expr(LiteralExpression<String>("barval")),
          Token.dedent,
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.key("key"),
          Token.indent,
          Token.key("foo"),
          Token.indent,
          Token.key("bar"),
          Token.expr(LiteralExpression<String>("barval")),
          Token.dedent,
          Token.key("baz"),
          Token.expr(LiteralExpression<String>("bazval")),
          Token.dedent,
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.listMark,
          Token.key("foo"),
          Token.number(1),
          Token.listMark,
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.listMark,
          Token.expr(LiteralExpression<String>("foo")),
          Token.listMark,
          Token.listMark,
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.listMark,
          Token.key("key"),
          Token.expr(LiteralExpression<String>("foo")),
          Token.key("value"),
          Token.number(1),
          Token.listMark,
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.key("key"),
          Token.indent,
          Token.listMark,
          Token.number(1),
          Token.listMark,
          Token.number(2),
          Token.dedent,
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.key("key"),
          Token.indent,
          Token.listMark,
          Token.key("some"),
          Token.expr(LiteralExpression<String>("foo")),
          Token.key("other"),
          Token.indent,
          Token.listMark,
          Token.expr(LiteralExpression<String>("bar")),
          Token.dedent,
          Token.listMark,
          Token.key("kuz"),
          Token.expr(LiteralExpression<String>("baz")),
          Token.dedent,
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

      expect(
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

      expect(
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

      expect(
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.directive("foobar", null),
          Token.indent,
          Token.key("nested"),
          Token.bool(true),
          Token.dedent,
        ],
      );
    });

    test("directive as key with map body", () {
      final source = [
        'foobar: @foobar "foo"',
        '  nested: @foobar "other"',
        '  foo: 2',
      ].join("\n");

      expect(
        tokenizer.tokenize(source),
        [
          Token.key("foobar"),
          Token.directive("foobar", [LiteralExpression("foo")]),
          Token.indent,
          Token.key("nested"),
          Token.directive("foobar", [LiteralExpression("other")]),
          Token.key("foo"),
          Token.number(2),
          Token.dedent,
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.key("foobar"),
          Token.directive("foobar", [LiteralExpression("foo")]),
          Token.indent,
          Token.listMark,
          Token.bool(true),
          Token.listMark,
          Token.bool(false),
          Token.dedent,
          Token.key("other"),
        ],
      );
    });

    test("directive with expressions", () {
      final source = ['@foobar 42'].join("\n");

      expect(
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

      expect(
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.listMark,
          Token.directive("foobar", null),
          Token.listMark,
          Token.directive("foobar", null),
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

      expect(
        tokenizer.tokenize(source),
        [
          Token.directive("foo", [VarExpression("var")]),
          Token.indent,
          Token.key("key"),
          Token.number(1),
          Token.directive("something", null),
          Token.directive("something", null),
          Token.dedent,
        ],
      );
    });
  });
}
