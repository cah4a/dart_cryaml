import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/tokenizer.dart';
import 'package:cryaml/src/token.dart';
import 'package:test/test.dart';

main() {
  final parser = Tokenizer();

  group("simplest", () {
    test("empty", () {
      expect(
        parser.parse(""),
        [],
      );
    });

    test("empty spaces", () {
      expect(
        parser.parse("  \n\n   \t"),
        [],
      );
    });

    test("int", () {
      expect(
        parser.parse("1"),
        [
          Token.expr(LiteralExpression<int>(1)),
        ],
      );
    });

    test("double", () {
      expect(
        parser.parse("3.14"),
        [
          Token.expr(LiteralExpression<double>(3.14)),
        ],
      );
    });

    test("string", () {
      expect(
        parser.parse('"foo"'),
        [
          Token.expr(LiteralExpression<String>("foo")),
        ],
      );
    });

    test("consume indents", () {
      expect(
        parser.parse('\n\n    foo: "bar"'),
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
        parser.parse(source),
        [
          Token.key("foo"),
          Token.expr(LiteralExpression<String>("value")),
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
        parser.parse(source),
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
        parser.parse(source),
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
        parser.parse(source),
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

    test("expect indent", () {
      final source = [
        "key:",
        'foo: 3',
      ].join("\n");

      expect(
        () => parser.parse(source),
        throwsA(TypeMatcher<FormatException>()),
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
        () => parser.parse(source),
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
        parser.parse(source),
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
        parser.parse(source),
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
        '',
        '- key: "bar"',
        '  value: null',
      ].join("\n");

      expect(
        parser.parse(source),
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
        parser.parse(source),
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
        parser.parse(source),
        [
          Token.directive("foobar", []),
        ],
      );
    });

    test("directive with body", () {
      final source = [
        '@foobar',
        '    nested: true',
      ].join("\n");

      expect(
        parser.parse(source),
        [
          Token.directive("foobar", []),
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
        parser.parse(source),
        [
          Token.directive("foobar", [
            LiteralExpression<int>(42),
          ]),
        ],
      );
    });

    test("directive with list of expressions", () {
      final source = [r'@foobar $var in [1, 2, $foo]'].join("\n");

      expect(
        parser.parse(source),
        [
          Token.directive("foobar", [
            VarExpression("var"),
            KeywordExpression("in"),
            ArrayExpression([
              LiteralExpression<int>(1),
              LiteralExpression<int>(2),
              VarExpression("foo"),
            ]),
          ]),
        ],
      );
    });
  });
}
