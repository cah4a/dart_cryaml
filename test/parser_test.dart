import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/nodes.dart';
import 'package:cryaml/src/parser.dart';
import 'package:cryaml/src/token.dart';
import 'package:cryaml/src/tokenizer.dart';
import 'package:test/test.dart';

void main() {
  group('literals', () {
    test('empty is null', () {
      final result = Parser().parse([]);
      expect(result, null);
    });

    test('literal', () {
      final result = Parser().parse([
        Token.expr(LiteralExpression<int>(1)),
      ]);

      expect(result, LiteralExpression<int>(1));
    });
  });

  group('arrays', () {
    test('array of expressions', () {
      final result = Parser().parse([
        Token.listMark(),
        Token.listMark(),
        Token.listMark(),
        Token.expr(LiteralExpression<int>(1)),
        Token.listMark(),
        Token.expr(VarExpression("bar")),
        Token.listMark(),
      ]);

      expect(result, [
        Expression.NULL,
        Expression.NULL,
        LiteralExpression<int>(1),
        VarExpression("bar"),
        Expression.NULL,
      ]);
    });

    test('array of onliner map', () {
      final result = Parser().parse([
        Token.listMark(),
        Token.key("foo"),
        Token.expr(LiteralExpression<int>(1)),
      ]);

      expect(
        result,
        [
          {"foo": LiteralExpression<int>(1)},
        ],
      );
    });

    test('array of map', () {
      final result = Parser().parse([
        Token.listMark(),
        Token.key("foo"),
        Token.listMark(),
        Token.key("bar"),
        Token.expr(LiteralExpression<int>(2)),
        Token.listMark(),
        Token.key("foo"),
        Token.expr(LiteralExpression<int>(3)),
        Token.key("baz"),
        Token.expr(LiteralExpression<int>(4)),
      ]);

      expect(result, [
        {
          "foo": Expression.NULL,
        },
        {
          "bar": LiteralExpression<int>(2),
        },
        {
          "foo": LiteralExpression<int>(3),
          "baz": LiteralExpression<int>(4),
        },
      ]);
    });

    test('array of mixed expressions ands maps', () {
      final result = Parser().parse([
        Token.listMark(),
        Token.expr(LiteralExpression<int>(1)),
        Token.listMark(),
        Token.key("baz"),
      ]);

      expect(result, [
        LiteralExpression<int>(1),
        {"baz": Expression.NULL},
      ]);
    });

    test('array of maps with nested values', () {
      final result = Parser().parse([
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
      ]);

      expect(result, {
        'key': [
          {
            'some': LiteralExpression<String>("foo"),
            'other': [LiteralExpression<String>("bar")]
          },
          {
            "kuz": LiteralExpression<String>("baz"),
          }
        ]
      });
    });
  });

  group('objects', () {
    test('simle object', () {
      final result = Parser().parse([
        Token.key("foo"),
        Token.key("bar"),
        Token.expr(VarExpression("bar")),
      ]);

      expect(result, {
        'foo': Expression.NULL,
        'bar': VarExpression("bar"),
      });
    });

    test('nested objects', () {
      final result = Parser().parse([
        Token.key("foo"),
        Token.expr(LiteralExpression<int>(1)),
        Token.key("bar"),
        Token.indent(),
        Token.key("baz"),
        Token.expr(LiteralExpression<int>(2)),
        Token.dedent(),
      ]);

      expect(result, {
        'foo': LiteralExpression<int>(1),
        'bar': {
          "baz": LiteralExpression<int>(2),
        },
      });
    });

    test('object with array', () {
      final result = Parser().parse([
        Token.key("foo"),
        Token.expr(LiteralExpression<int>(1)),
        Token.key("bar"),
        Token.indent(),
        Token.listMark(),
        Token.expr(LiteralExpression<int>(2)),
        Token.dedent(),
      ]);

      expect(result, {
        'foo': LiteralExpression<int>(1),
        'bar': [
          LiteralExpression<int>(2),
        ]
      });
    });
  });

  group('directives', () {
    test("arguments", () {
      final arguments = [Object()];

      final result = Parser().parse([
        Token.directive("foobar", arguments),
      ]);

      expect(
        result,
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foobar")
            .having((node) => node.arguments, "arguments", arguments)
            .having((node) => node.document, "document", null)
            .having((node) => node.children, "children", null),
      );
    });

    test("expresion document", () {
      final arguments = [Object()];
      final object = Object();

      final result = Parser().parse([
        Token.directive("foobar", arguments),
        Token.indent(),
        Token.expr(LiteralExpression<Object>(object)),
        Token.dedent(),
      ]);

      final document = LiteralExpression<Object>(object);

      expect(
        result,
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foobar")
            .having((node) => node.arguments, "arguments", arguments)
            .having((node) => node.document, "document", document)
            .having((node) => node.children, "children", null),
      );
    });

    test("map document", () {
      final arguments = [Object()];
      final object = Object();

      final result = Parser().parse([
        Token.directive("foobar", arguments),
        Token.indent(),
        Token.key("foo"),
        Token.expr(LiteralExpression<Object>(object)),
        Token.dedent(),
      ]);

      final document = {
        "foo": LiteralExpression<Object>(object),
      };

      expect(
        result,
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foobar")
            .having((node) => node.arguments, "arguments", arguments)
            .having((node) => node.document, "document", document)
            .having((node) => node.children, "children", null),
      );
    });

    test("list document", () {
      final result = Parser().parse([
        Token.directive('foobar', null),
        Token.indent(),
        Token.listMark(),
        Token.expr(LiteralExpression<int>(1)),
        Token.listMark(),
        Token.expr(LiteralExpression<int>(2)),
        Token.dedent(),
      ]);

      expect(
        result,
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foobar")
            .having((node) => node.document, "document", [
          LiteralExpression<int>(1),
          LiteralExpression<int>(2),
        ]),
      );
    });

    test("list of directives", () {
      final result = Parser().parse([
        Token.listMark(),
        Token.directive("foo", null),
        Token.listMark(),
        Token.directive("bar", null),
        Token.indent(),
        Token.key("f"),
        Token.dedent(),
        Token.listMark(),
        Token.directive("baz", null),
      ]);

      expect(result, [
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foo"),
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "bar")
            .having(
                (node) => node.document, "document", {"f": Expression.NULL}),
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "baz"),
      ]);
    });

    test("directive children", () {
      final result = Parser().parse([
        Token.directive('foobar', null),
        Token.indent(),
        Token.directive('foo', null),
        Token.directive('bar', null),
        Token.dedent(),
      ]);

      final children = [
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foo"),
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "bar"),
      ];

      expect(
        result,
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foobar")
            .having((node) => node.arguments, "arguments", null)
            .having((node) => node.document, "document", null)
            .having((node) => node.children, "children", children),
      );
    });

    test("child directives as key", () {
      final result = Parser().parse([
        Token.key("first"),
        Token.directive('foobar', null),
        Token.indent(),
        Token.listMark(),
        Token.bool(true),
        Token.listMark(),
        Token.bool(false),
        Token.dedent(),
        Token.key("other"),
      ]);

      final document = [
        Expression.TRUE,
        Expression.FALSE,
      ];

      expect(
        result,
        {
          "first": TypeMatcher<CrYAMLDirectiveNode>()
              .having((node) => node.name, "name", "foobar")
              .having((node) => node.arguments, "arguments", null)
              .having((node) => node.document, "document", document)
              .having((node) => node.children, "children", null),
          "other": LiteralExpression<Null>(null),
        },
      );
    });

    test("map document with child directives", () {
      final result = Parser().parse([
        Token.directive('foobar', null),
        Token.indent(),
        Token.key("value"),
        Token.expr(LiteralExpression<int>(1)),
        Token.directive('foo', null),
        Token.directive('bar', null),
        Token.dedent(),
      ]);

      final children = [
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foo"),
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "bar"),
      ];

      final document = {
        "value": LiteralExpression<int>(1),
      };

      expect(
        result,
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foobar")
            .having((node) => node.arguments, "arguments", null)
            .having((node) => node.document, "document", document)
            .having((node) => node.children, "children", children),
      );
    });

    test("list document with child directives", () {
      final result = Parser().parse([
        Token.directive('foobar', null),
        Token.indent(),
        Token.listMark(),
        Token.expr(LiteralExpression<int>(42)),
        Token.directive('foo', null),
        Token.directive('bar', null),
        Token.dedent(),
      ]);

      final children = [
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foo"),
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "bar"),
      ];

      final document = [
        LiteralExpression<int>(42),
      ];

      expect(
        result,
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "foobar")
            .having((node) => node.arguments, "arguments", null)
            .having((node) => node.document, "document", document)
            .having((node) => node.children, "children", children),
      );
    });

    test('double nested directives', () {
      final tokens = Tokenizer().tokenize("""
        @group
          @nested
            key: false
          @nested
      """);

      final result = Parser().parse(tokens);

      final children = [
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "nested")
            .having(
          (node) => node.document,
          "document",
          {"key": Expression.FALSE},
        ),
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "nested"),
      ];

      expect(
        result,
        TypeMatcher<CrYAMLDirectiveNode>()
            .having((node) => node.name, "name", "group")
            .having((node) => node.children, "children", children),
      );
    });
  });
}
