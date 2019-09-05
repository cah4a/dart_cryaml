import 'package:cryaml/src/expression_parser.dart';
import 'package:cryaml/src/expressions.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

dynamic parse(String value, {some}) {
  final result = (expressionParser & endOfInput()).parse(value);

  if (result.isFailure) {
    throw FormatException(result.message, result.buffer, result.position);
  }

  return result.value.first;
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

  test('escape codes', () {
    expect(parse(r'"foo \" bar"'), LiteralExpression<String>("foo \" bar"));
    expect(parse(r'"foo \\"'), LiteralExpression<String>(r"foo \"));
    expect(parse(r'"foo \n"'), LiteralExpression<String>("foo \n"));
  });

  test("interpolation", () {
    expect(
      parse(r'"some \$var"'),
      LiteralExpression<String>("some \$var"),
    );

    expect(
      parse(r'"foo$var"'),
      InterpolateExpression([
        LiteralExpression<String>("foo"),
        VarExpression("var"),
      ]),
    );

    expect(
      parse(r'"foo#{$var}"'),
      InterpolateExpression([
        LiteralExpression<String>("foo"),
        VarExpression("var"),
      ]),
    );

    expect(
      parse(r'"foo#{foo($var)}"'),
      InterpolateExpression([
        LiteralExpression<String>("foo"),
        CallExpression("foo", [
          VarExpression("var"),
        ]),
      ]),
    );
  });

  test('number', () {
    expect(parse('100500'), LiteralExpression(100500));
    expect(parse('36.6'), LiteralExpression(36.6));
  });

  test('empty array', () {
    expect(
      parse('[  ]'),
      ArrayExpression([]),
    );
  });

  test('array', () {
    expect(
      parse('[1, "foo", 3 + 1, \$var]'),
      ArrayExpression([
        LiteralExpression<int>(1),
        LiteralExpression<String>("foo"),
        BinaryExpression(
          LiteralExpression<int>(3),
          "+",
          LiteralExpression<int>(1),
        ),
        VarExpression("var"),
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
      parse('foobar( )'),
      CallExpression("foobar"),
    );
  });

  test('call positional args', () {
    expect(
      parse('foobar( 1, true )'),
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

  test('namespace call', () {
    expect(
      parse('prefix.foobar()'),
      CallExpression("prefix.foobar"),
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
        ]),
      ),
    );
  });

  test('comments', () {
    expect(
      parse("200 # comment"),
      LiteralExpression<int>(200),
    );

    expect(
      parse("[ # comm\n 200, \n 500 \n ]"),
      ArrayExpression([
        LiteralExpression<int>(200),
        LiteralExpression<int>(500),
      ]),
    );
  });

  test('comments in calls', () {
    expect(
      parse("foo( # comment\n) # other comment"),
      CallExpression("foo"),
    );

    expect(
      parse("foo( # comment\n 3) # other comment"),
      CallExpression("foo", [LiteralExpression<int>(3)]),
    );

    expect(
      parse("foo( # comment\n "
          "3, #(123, ]]3\n"
          "named: 5 #comment\n"
          ") # other comment"),
      CallExpression("foo", [
        LiteralExpression<int>(3)
      ], {
        "named": LiteralExpression<int>(5),
      }),
    );
  });
}
