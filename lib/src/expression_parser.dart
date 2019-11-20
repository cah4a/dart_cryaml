/// Expression parsing using petitparser.
///
/// Very bad fails handling. Could be rewritten to achieve better error messages
/// And maybe parsing performance could be better
///
/// But rewrite will take a lot of time

import 'package:petitparser/petitparser.dart';

import 'expressions.dart';

final expressionParser = GrammarParser(_ExpressionGrammar());

class _ExpressionGrammar extends GrammarDefinition {
  Parser start() => ref(expression);

  Parser expression() => comment(
        ref(node).separatedBy(operations).map(parseExpression),
      );

  Parser node() =>
      literals |
      variable |
      numberToken |
      ref(string) |
      ref(call) |
      ref(array) |
      ref(group);

  Parser string() => (char('"') &
              (interpolateVar() | interpolate() | characterPrimitive).star() &
              char('"'))
          .map((each) {
        final result = <Expression>[];
        final builder = StringBuffer();

        for (var char in each[1]) {
          if (char is Expression) {
            if (builder.isNotEmpty) {
              result.add(LiteralExpression<String>(builder.toString()));
              builder.clear();
            }

            result.add(char);
          } else {
            builder.write(char);
          }
        }

        if (result.isEmpty) {
          return LiteralExpression<String>(builder.toString());
        }

        if (builder.isNotEmpty) {
          result.add(LiteralExpression<String>(builder.toString()));
        }

        return InterpolateExpression(result);
      });

  Parser interpolateVar() => variable;

  Parser interpolate() =>
      (char("#") & char("{") & ref(node) & char("}")).map((each) => each[2]);

  Parser group() =>
      (char("(") & ref(expression) & char(")")).map((match) => match[1]);

  Parser comment(Parser prefix) =>
      (prefix & commentToken.optional()).map(parseComment);

  Parser array() => (comment(char("[").trim()) &
          ref(expression)
              .separatedBy(
                comment(char(",").trim()),
                includeSeparators: false,
              )
              .optional() &
          comment(char("]").trim()))
      .map(parseArray);

  Parser call() => (funcNameToken &
          comment(char("(") & whitespace().star()) &
          ref(positionalArguments).trim().optional() &
          ref(namedArguments).trim().optional() &
          comment(char(")")))
      .map(parseCall);

  Parser positionalArguments() => ref(expression).separatedBy(
        comment(char(",").trim()),
        includeSeparators: false,
        optionalSeparatorAtEnd: true,
      );

  Parser namedArguments() => ref(named)
      .separatedBy(
        comment(char(",").trim()),
        includeSeparators: false,
        optionalSeparatorAtEnd: true,
      )
      .map(parseNamedArgs);

  Parser named() => argNameToken & char(":").trim() & ref(expression);
}

Parser literal<T>(T constant) => string(constant.toString())
    .flatten('${constant} expected')
    .map((_) => LiteralExpression(constant));

Parser keyword(String message) =>
    (letter() & pattern("A-Za-z0-9_").plus()).flatten(message);

final characterPrimitive = characterNormal | characterEscape | characterUnicode;

final characterNormal = pattern('^"\\');
final characterEscape =
    (char('\\') & pattern(jsonEscapeChars.keys.join()).optional()).map(
  (each) => jsonEscapeChars[each[1]] ?? "",
);
final characterUnicode = string('\\u') & pattern('0-9A-Fa-f').times(4);

final keywordToken = keyword("Keyword expected");

final funcNameToken = (pattern("A-Za-z_") & pattern("A-Za-z0-9_").star())
    .separatedBy(char("."))
    .flatten("function name expected");

final argNameToken = keyword("argument name expected");

final literals = literal(null) | literal(false) | literal(true);

final commentToken =
    char("#").trim() & Token.newlineParser().neg().star().trim();

final variable =
    (char(r"$") & pattern("A-Za-z_") & pattern("A-Za-z0-9_").star())
        .flatten("Variable expected")
        .map((each) => VarExpression(each.substring(1)));

final numberToken = (char('-').optional() &
        char('0').or(digit().plus()) &
        char('.').seq(digit().plus()).optional() &
        pattern('eE')
            .seq(pattern('-+').optional())
            .seq(digit().plus())
            .optional())
    .flatten("number expected")
    .map(parseNumber);

final operations = _OperationsParser().trim();

Expression parseNumber(each) {
  final floating = double.parse(each);
  final integral = floating.toInt();
  if (floating == integral && each.indexOf('.') == -1) {
    return LiteralExpression<int>(integral);
  } else {
    return LiteralExpression<double>(floating);
  }
}

dynamic parseComment(List each) => each.first;

Expression parseArray(List each) {
  if (each[1] == null) {
    return ArrayExpression([]);
  }

  return ArrayExpression(each[1].cast<Expression>());
}

const jsonEscapeChars = {
  '\\': '\\',
  '/': '/',
  '"': '"',
  'b': '\b',
  'f': '\f',
  'n': '\n',
  'r': '\r',
  't': '\t',
  '\$': '\$'
};

Expression parseCall(List each) {
  return CallExpression(
    each[0],
    each[2]?.cast<Expression>(),
    each[3],
  );
}

Map<String, Expression> parseNamedArgs(List each) {
  final data = each.map(
    (item) => MapEntry<String, Expression>(
      item[0],
      item[2],
    ),
  );

  return Map<String, Expression>.fromEntries(data);
}

Expression parseExpression(List each) {
  assert(each.length % 2 == 1);

  if (each.length == 1) {
    return each.first;
  }

  while (each.length > 3) {
    int index = 1;
    int most = BinaryExpression.operations[each[1]];

    for (int i = 0; i < each.length; i++) {
      final value = each[i];

      if (value is! String) {
        continue;
      }

      final order = BinaryExpression.operations[value];

      if (order < most) {
        most = order;
        index = i;
      }
    }

    each.replaceRange(index - 1, index + 2, [
      BinaryExpression(
        each[index - 1],
        each[index],
        each[index + 1],
      )
    ]);
  }

  return BinaryExpression(each[0], each[1], each[2]);
}

class _OperationsParser extends Parser {
  final operations = BinaryExpression.operations.keys.toList()
    ..sort((l, r) => r.length.compareTo(l.length));

  @override
  Parser copy() => _OperationsParser();

  @override
  Result parseOn(Context context) {
    final start = context.position;

    for (final operation in operations) {
      final stop = start + operation.length;

      if (stop <= context.buffer.length) {
        final result = context.buffer.substring(start, stop);

        if (result == operation) {
          return context.success(result, stop);
        }
      }
    }

    return context.failure("Operation expected");
  }
}
