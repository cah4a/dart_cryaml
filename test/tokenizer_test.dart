import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/tokenizer.dart';
import 'package:cryaml/src/token.dart';
import 'package:test/test.dart';

main() {
  final parser = Tokenizer();

  group("simplest", () {
    test("empty", () {
      expect(
        parser.tokenize(""),
        [],
      );
    });

    test("empty spaces", () {
      expect(
        parser.tokenize("  \n\n   \t"),
        [],
      );
    });

    test("int", () {
      expect(
        parser.tokenize("1"),
        [
          Token.expr(LiteralExpression<int>(1)),
        ],
      );
    });

    test("double", () {
      expect(
        parser.tokenize("3.14"),
        [
          Token.expr(LiteralExpression<double>(3.14)),
        ],
      );
    });

    test("string", () {
      expect(
        parser.tokenize('"foo"'),
        [
          Token.expr(LiteralExpression<String>("foo")),
        ],
      );
    });

    test("consume indents", () {
      expect(
        parser.tokenize('\n\n    foo: "bar"'),
        [
          Token.key("foo"),
          Token.expr(LiteralExpression<String>("bar")),
        ],
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
        parser.tokenize(source),
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
        parser.tokenize(source),
        [
          Token.key("foo"),
          Token.key("bar"),
          Token.expr(LiteralExpression<String>("value")),
        ],
      );
    });

    test("ignore empty lines", () {
      final source = [
        'foo: "value"',
        //'  ',
        'bar: "value"',
      ].join("\n");

      expect(
        parser.tokenize(source),
        [
          Token.key("foo"),
          Token.expr(LiteralExpression<String>("value")),
          Token.key("bar"),
          Token.expr(LiteralExpression<String>("value")),
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
        parser.tokenize(source),
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
        parser.tokenize(source),
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
        () => parser.tokenize(source),
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
        parser.tokenize(source),
        [
          Token.listMark,
          Token.key("foo"),
          Token.expr(LiteralExpression<int>(1)),
          Token.listMark,
          Token.key("bar"),
          Token.expr(LiteralExpression<int>(2)),
        ],
      );
    });

    test("list of strings", () {
      final source = [
        '- "foo"',
        '- "bar"',
      ].join("\n");

      expect(
        parser.tokenize(source),
        [
          Token.listMark,
          Token.expr(LiteralExpression<String>("foo")),
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
        parser.tokenize(source),
        [
          Token.listMark,
          Token.key("key"),
          Token.expr(LiteralExpression<String>("foo")),
          Token.key("value"),
          Token.expr(LiteralExpression<int>(1)),
          Token.listMark,
          Token.key("key"),
          Token.expr(LiteralExpression<String>("bar")),
          Token.key("value"),
          Token.expr(LiteralExpression<Null>(null)),
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
        parser.tokenize(source),
        [
          Token.key("key"),
          Token.indent,
          Token.listMark,
          Token.expr(LiteralExpression<int>(1)),
          Token.listMark,
          Token.expr(LiteralExpression<int>(2)),
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
        parser.tokenize(source),
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
        parser.tokenize(source),
        [
          Token.key("str"),
          Token.expr(LiteralExpression<String>("string")),
          Token.key("int"),
          Token.number(42),
          Token.key("double"),
          Token.number(36.6),
          Token.key("null"),
          Token.expr(LiteralExpression<Null>(null)),
        ],
      );
    });
  });

  group("directives", () {
    test("oneliner", () {
      final source = ['@foobar'].join("\n");

      expect(
        parser.tokenize(source),
        [
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
        parser.tokenize(source),
        [
          Token.directive("foobar", null),
          Token.indent,
          Token.key("nested"),
          Token.expr(LiteralExpression<bool>(true)),
          Token.dedent,
        ],
      );
    });

    test("directive with expressions", () {
      final source = ['@foobar 42'].join("\n");

      expect(
        parser.tokenize(source),
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
        r'$foo + 5.0]'
      ].join("\n");

      expect(
        parser.tokenize(source),
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
        parser.tokenize(source),
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
      ].join("\n");

      expect(
        parser.tokenize(source),
        [
          Token.directive("foo", [VarExpression("var")]),
          Token.indent,
          Token.key("key"),
          Token.expr(LiteralExpression<int>(1)),
          Token.directive("something", null),
          Token.dedent,
        ],
      );
    });
  });
}
