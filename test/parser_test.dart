import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/parser.dart';
import 'package:cryaml/src/token.dart';
import 'package:test/test.dart';

void main() {
  group('literals', () {
    test('simle object', () {
      final result = Parser().parse([]);
      expect(result, null);
    });

    test('literal', () {
      final result = Parser().parse([
        Token.expr(LiteralExpression<int>(1)),
      ]);

      expect(result, LiteralExpression<int>(1));
    });

    test('directive', () {
      final result = Parser().parse([
        Token.directive("foo", []),
      ]);

      expect(result, Token.directive("foo", []));
    });
  });

  group('arrays', () {
    test('array of expressions', () {
      final result = Parser().parse([
        Token.listMark,
        Token.expr(LiteralExpression<int>(1)),
        Token.listMark,
        Token.expr(VarExpression("bar")),
      ]);

      expect(result, [
        LiteralExpression<int>(1),
        VarExpression("bar"),
      ]);
    });

    test('array of hash', () {
      final result = Parser().parse([
        Token.listMark,
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

    test('array of objects', () {
      final result = Parser().parse([
        Token.listMark,
        Token.key("foo"),
        Token.expr(LiteralExpression<int>(1)),
        Token.key("bar"),
        Token.expr(LiteralExpression<int>(2)),
        Token.listMark,
        Token.key("foo"),
        Token.expr(LiteralExpression<int>(3)),
        Token.key("baz"),
        Token.expr(LiteralExpression<int>(4)),
      ]);

      expect(result, [
        {"foo": LiteralExpression<int>(1), "bar": LiteralExpression<int>(2)},
        {"foo": LiteralExpression<int>(3), "baz": LiteralExpression<int>(4)},
      ]);
    });
  });

  group('objects', () {
    test('simle object', () {
      final result = Parser().parse([
        Token.key("foo"),
        Token.expr(LiteralExpression<int>(1)),
        Token.key("bar"),
        Token.expr(VarExpression("bar")),
      ]);

      expect(result, {
        'foo': LiteralExpression<int>(1),
        'bar': VarExpression("bar"),
      });
    });

    test('nested objects', () {
      final result = Parser().parse([
        Token.key("foo"),
        Token.expr(LiteralExpression<int>(1)),
        Token.key("bar"),
        Token.indent,
        Token.key("baz"),
        Token.expr(LiteralExpression<int>(2)),
        Token.dedent,
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
        Token.indent,
        Token.listMark,
        Token.expr(LiteralExpression<int>(2)),
        Token.dedent,
      ]);

      expect(result, {
        'foo': LiteralExpression<int>(1),
        'bar': [
          LiteralExpression<int>(2),
        ]
      });
    });
  });
}
