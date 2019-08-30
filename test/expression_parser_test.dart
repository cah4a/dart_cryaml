import 'package:cryaml/src/expression_parser.dart';
import 'package:cryaml/src/expressions.dart';
import 'package:test/test.dart';

dynamic parse(String value) {
  final result = expressionParser.parse(value);

  if (result.isFailure) {
    throw FormatException(result.message, result.buffer, result.position);
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
      parse('[1, "foo", 3 + 1]'),
      ArrayExpression([
        LiteralExpression<int>(1),
        LiteralExpression<String>("foo"),
        BinaryExpression(
          LiteralExpression<int>(3),
          "+",
          LiteralExpression<int>(1),
        ),
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

  test('call combined arguments', () {
    expect(
      parse('foobar(1, answer: 42)'),
      CallExpression(
        "foobar",
        [
          LiteralExpression<int>(1),
        ],
        {
          "answer": LiteralExpression<int>(42),
        },
      ),
    );
  });

  test('call expression arguments', () {
    expect(
      parse('foobar(1   / 2 \n,\t 2, arg: 5 + \$var)'),
      CallExpression(
        "foobar",
        [
          BinaryExpression(
            LiteralExpression<int>(1),
            "/",
            LiteralExpression<int>(2),
          ),
          LiteralExpression<int>(2)
        ],
        {
          "arg": BinaryExpression(
            LiteralExpression<int>(5),
            "+",
            VarExpression("var"),
          ),
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

  test('binary with grouping', () {
    expect(
      parse(r"202 + ($number + 4)"),
      BinaryExpression(
        LiteralExpression<int>(202),
        "+",
        BinaryExpression(
          VarExpression("number"),
          "+",
          LiteralExpression<int>(4),
        ),
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

  test('new lines, tabs, other stuff', () {
    expect(
      parse("200 \n\n + [\n\n3.0  \t , 7.0 \n\t\t]"),
      BinaryExpression(
          LiteralExpression<int>(200),
          "+",
          ArrayExpression([
            LiteralExpression<double>(3),
            LiteralExpression<double>(7),
          ])),
    );
  });
}
