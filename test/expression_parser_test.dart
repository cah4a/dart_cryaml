import 'package:cryaml/src/expression_parser.dart';
import 'package:cryaml/src/expressions.dart';
import 'package:test/test.dart';

dynamic parse(String value) {
  final result = expressionParser.parse(value);

  if (result.isFailure) {
    throw result.message;
  }

  return result.value;
}

void main() {
  test('null', () {
    expect(parse("null"), LiteralExpression(null));
  });

  test('true', () {
    expect(parse("true"), LiteralExpression<bool>(true));
  });

  test('false', () {
    expect(parse("false"), LiteralExpression<bool>(false));
  });

  test('string', () {
    expect(parse('"foobarbaz"'), LiteralExpression<String>("foobarbaz"));
  });

  test('number', () {
    expect(parse('100500'), LiteralExpression(100500));
    expect(parse('36.6'), LiteralExpression(36.6));
  });

  test('array', () {
    expect(
      parse('[1, "foo", 3]'),
      ArrayExpression([
        LiteralExpression<int>(1),
        LiteralExpression<String>("foo"),
        LiteralExpression<int>(3),
      ]),
    );
  });

  test("var", () {
    expect(
      parse('\$foobar'),
      VarExpression("foobar"),
    );
  });

  test('call', () {
    expect(
      parse('foobar()'),
      CallExpression("foobar"),
    );
  });

  test('call positional args', () {
    expect(
      parse('foobar(1, true)'),
      CallExpression("foobar", [
        LiteralExpression<int>(1),
        LiteralExpression<bool>(true),
      ]),
    );
  });

  test('call named args', () {
    expect(
      parse('foobar(something: true, answer: 42)'),
      CallExpression(
        "foobar",
        null,
        {
          "something": LiteralExpression<bool>(true),
          "answer": LiteralExpression<int>(42),
        },
      ),
    );
  });

  test('binary expression', () {
    expect(
      parse(r"202 + $number"),
      BinaryExpression(
        LiteralExpression<int>(202),
        "+",
        VarExpression("number"),
      ),
    );
  });

  test('binary expression complex', () {
    expect(
      parse(r"202 + pi() * $number"),
      BinaryExpression(
        LiteralExpression<int>(202),
        "+",
        BinaryExpression(
          CallExpression("pi"),
          "*",
          VarExpression("number"),
        ),
      ),
    );
  });
}
