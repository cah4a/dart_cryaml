import 'dart:math';

import 'package:cryaml/src/expression_parser.dart';
import 'package:cryaml/src/indentator.dart';
import 'package:cryaml/src/token.dart';
import 'package:petitparser/petitparser.dart' as pp;

/// tokenize cryaml tree
class Tokenizer {
  const Tokenizer();

  Iterable<Token> tokenize(String source) sync* {
    Context ctx = Context(source);

    if (source.isEmpty) {
      return;
    }

    while (!ctx.isEnd) {
      yield* ctx.execute();
    }

    yield* ctx.indentation();
  }
}

typedef Iterable<Token> State(Context context);

class Context {
  final indentator = Indentator();
  final String buffer;

  Context(this.buffer);

  State state = begin;
  int pos = 0;

  bool get isEnd => pos >= buffer.length;

  void ensureNewLine() {
    while (!isEnd) {
      switch (char) {
        case " ":
        case "\t":
          pos++;
          continue;
        case "\n":
          pos++;
          return;
        default:
          fail("Expected new line. Got '$char' instead");
      }
    }
  }

  String grabUntil(Pattern pattern, String message) {
    final result = grabTo(pattern, message);
    pos++;
    return result;
  }

  String grabTo(Pattern pattern, String message) {
    final result = tryGrabTo(pattern);

    if (result == null) {
      fail(message);
    }

    return result;
  }

  String tryGrabTo(Pattern pattern) {
    final index = buffer.indexOf(pattern, pos);

    if (index == -1) {
      return null;
    }

    final result = buffer.substring(pos, index);
    pos = index;
    return result;
  }

  String skip(Pattern pattern) {
    final result = lookahead(pattern);
    if (result != null) {
      pos += result.length;
    }
    return result;
  }

  String lookahead(Pattern pattern) {
    final match = pattern.matchAsPrefix(buffer, pos);
    return match?.group(0);
  }

  String get char => buffer[pos];

  String chars(length) => buffer.substring(
        pos,
        min(pos + length, buffer.length),
      );

  String consumeChar() => buffer[pos++];

  trim() {
    while (!isEnd && (char == " " || char == "\t")) {
      pos++;
    }
  }

  Iterable<Token> indentation() sync* {
    final startPos = pos;
    final indent = grabTo(RegExp(r"\S|$|\n"), "Dedent expected");
    final isListMark = !isEnd && char == "-";

    if (indent.contains("\t")) {
      fail(
        "Tab characters are not allowed as indentation.",
        startPos + indent.indexOf("\t"),
      );
    }

    final newIndent = pos - startPos;
    int listMarkIndent;

    if (isListMark) {
      pos++;
      trim();
      listMarkIndent = pos - startPos;
    }

    for (final indent in indentator(newIndent, listMarkIndent)) {
      switch (indent) {
        case Indentation.indent:
          yield Token.indent(pos);
          break;
        case Indentation.dedent:
          yield Token.dedent(pos);
          break;
        case Indentation.listIndent:
          yield Token.listMark(startPos + newIndent);
          break;
        case Indentation.unknown:
          fail("Undefined indentation");
          break;
      }
    }
  }

  fail(String message, [int position]) {
    throw FormatException(message, buffer, position ?? pos);
  }

  Iterable<Token> execute() sync* {
    final next = state;
    state = null;
    yield* next(this);
  }
}

Iterable<Token> begin(Context context) sync* {
  context.state = start;
}

Iterable<Token> start(Context context) sync* {
  context.skip(RegExp(r"[\s\t]*(?:#.*?)?(?:\n|$)"));

  yield* context.indentation();

  if (context.isEnd) {
    return;
  }

  if (context.char == "@") {
    context.consumeChar();
    context.state = directive;
    return;
  }

  if (context.chars(2) == "- ") {
    context.consumeChar();
    context.trim();
    yield Token.listMark(context.pos);
    context.state = start;
    return;
  }

  final key = context.lookahead(RegExp("[A-Za-z][A-Za-z0-9-_]*[\s\t]*:"));

  if (key != null) {
    yield Token.key(key.substring(0, key.length - 1).trim(), context.pos);
    context.pos += key.length;
    context.trim();
    context.state = objectValue;
    return;
  }

  context.state = expression;
}

Iterable<Token> directive(Context context) sync* {
  final startPos = context.pos - 1;

  final name = context.grabTo(
    RegExp(r"\n|\s|$"),
    "Newline or space or eof expected",
  );

  context.trim();

  final args = parseExpression(
    (expressionParser | keywordToken)
        .separatedBy(
          pp.char(" ").plus(),
          includeSeparators: false,
        )
        .optional(),
    context,
  );

  yield Token.directive(name, args, startPos);
  context.trim();
  context.ensureNewLine();
  context.state = start;
}

Iterable<Token> objectValue(Context context) sync* {
  if (context.char == "#") {
    context.grabTo(RegExp(r"\n|$"), "Expect new line");
  }

  if (context.isEnd) {
    return;
  }

  switch (context.char) {
    case "\n":
      context.consumeChar();
      context.state = start;
      break;
    case "@":
      context.consumeChar();
      context.state = directive;
      break;
    default:
      context.state = expression;
  }
}

Iterable<Token> expression(Context context) sync* {
  final startPos = context.pos;
  final expression = parseExpression(expressionParser, context);
  if (expression != null) {
    yield Token.expr(expression, startPos);
  }
  context.state = start;
  context.ensureNewLine();
}

dynamic parseExpression(pp.Parser parser, Context context) {
  final startPosition = context.pos;

  int expectEndOfExpr = 0;

  loop:
  while (!context.isEnd) {
    switch (context.char) {
      case "(":
      case "[":
      case "{":
        expectEndOfExpr++;
        break;
      case ")":
      case "]":
      case "}":
        expectEndOfExpr--;
        break;
      case "\n":
        if (expectEndOfExpr <= 0) {
          break loop;
        }
    }
    context.pos++;
  }

  final source = context.buffer.substring(startPosition, context.pos);

  if (source.trim().isEmpty) {
    return null;
  }

  final result = parser.parseOn(pp.Context(
    source,
    0,
  ));

  if (result.isFailure) {
    context.fail(
      "Wrong expression: ${result.message}",
      startPosition + result.position,
    );
  }

  if (context.pos > startPosition + result.position) {
    context.fail(
      "Unexpected end of expression",
      startPosition + result.position,
    );
  }

  if (context.pos < startPosition + result.position) {
    context.fail(
      "End of expression expected",
      startPosition + result.position,
    );
  }

  return result.value;
}
