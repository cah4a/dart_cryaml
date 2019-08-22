import 'dart:math';

import 'package:cryaml/src/exceptions.dart';
import 'package:cryaml/src/expression_parser.dart';
import 'package:cryaml/src/token.dart';
import 'package:cryaml/src/utils.dart';
import 'package:petitparser/petitparser.dart' as pp;

import 'expressions.dart';

/// tokenize cryaml tree
class Tokenizer {
  const Tokenizer();

  Iterable<Token> parse(String source) sync* {
    Context ctx = Context(source);

    if (source.isEmpty) {
      return;
    }

    while (!ctx.isEnd) {
      yield* ctx.execute();
    }

    yield* ctx.dedent();
  }
}

typedef Iterable<Token> State(Context context);

class Context {
  final String buffer;

  Context(this.buffer);

  State state = begin;
  int pos = 0;
  int indent;

  List<int> indents = [];

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
    while (!isEnd && [" "].contains(char)) {
      pos++;
    }
  }

  Token ensureIndent() {
    if (adviceIndent().isEmpty) {
      fail("Indent expected");
    }
    return Token.indent;
  }

  Iterable<Token> adviceIndent() sync* {
    final nextStartLine = buffer.indexOf(RegExp(r"\S|$"), pos);
    final newIndent = nextStartLine - pos;
    if (newIndent <= indent) {
      return;
    }
    indent = newIndent;
    indents.add(newIndent);
    yield Token.indent;
  }

  Iterable<Token> dedent() sync* {
    final pref = grabTo(RegExp(r"\S|$|\n"), "Dedent expected");

    if (pref.length > indent) {
      fail("Unexpected indent");
    }

    while (pref.length < indent && indents.length > 1) {
      yield Token.dedent;
      indents.removeLast();
      indent = indents.last;
    }

    if (pref.length > indent) {
      fail("Undefined indentation");
    }
  }

  fail(String message, [int position]) {
    throw CrYAMLException(message, buffer, position ?? pos);
  }

  Iterable<Token> execute() sync* {
    final next = state;
    state = null;
    yield* next(this);
  }
}

Iterable<Token> begin(Context context) sync* {
  final block = context.lookahead(RegExp(r"[\s\n\t\r]*"));
  final lineStart = max(0, context.buffer.lastIndexOf("\n", block.length));
  final indent = block.length - lineStart;

  context.pos = lineStart;
  context.indent = indent;
  context.indents = [indent];
  context.state = start;
}

Iterable<Token> start(Context context) sync* {
  context.skip(RegExp(r"[\s\t]*(?:\n|$)"));

  yield* context.dedent();

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
    yield Token.listMark;
    context.state = start;
    return;
  }

  final key = context.grabUntil(":", "Semicolon expected");
  yield Token.key(key);
  context.trim();
  context.state = objectValue;
}

Iterable<Token> directive(Context context) sync* {
  final name = context.grabTo(
    RegExp(r"\n|\s|$"),
    "Newline or space or eof expected",
  );

  context.trim();

  final args = <Expression>[];

  while (!context.isEnd && context.char != "\n") {
    args.add(parseExpression(context));
    context.trim();
  }

  yield Token.directive(name, args);
  context.trim();
  context.ensureNewLine();
  yield* context.adviceIndent();
  context.state = start;
}

Iterable<Token> objectValue(Context context) sync* {
  switch (context.char) {
    case "\n":
      context.consumeChar();
      yield context.ensureIndent();
      context.state = start;
      break;
    default:
      context.state = expression;
  }
}

Iterable<Token> expression(Context context) sync* {
  yield Token.expr(parseExpression(context));
  context.state = start;
  context.ensureNewLine();
}

Expression parseExpression(Context context) {
  final result = expressionParser.parseOn(pp.Context(
    context.buffer,
    context.pos,
  ));

  if (result.isFailure) {
    context.fail(result.message, result.position);
  }

  context.pos = result.position;
  return result.value;
}
