import 'package:cryaml/src/utils.dart';

class CrYAMLException extends FormatException {
  final String buffer;
  final int position;

  CrYAMLException(String message, this.buffer, this.position) : super(message);

  int _lineStart(int position) {
    final pos = buffer.lastIndexOf("\n", position);
    return pos == -1 ? 0 : pos + 1;
  }

  int _lineEnd(int position) {
    final pos = buffer.indexOf("\n", position);
    return pos == -1 ? buffer.length : pos;
  }

  @override
  String toString() {
    final textpos = lineAndColumnOf(buffer, position);
    final line = textpos[0];
    final col = textpos[1];
    final errorLineStart = _lineStart(position);
    final errorLineEnd = _lineEnd(position);

    final offset = line.toString().length;

    String code = "$line | " + buffer.substring(errorLineStart, errorLineEnd);

    if (errorLineStart > 0) {
      final prevLineStart = _lineStart(errorLineStart - 1);
      code = (line - 1).toString().padLeft(offset) + " | " +
          buffer.substring(prevLineStart, errorLineStart) +
          "\n" +
          code;
    }

    return "Error on line $line, column $col: $message\n\n"
        "$code\n" +
        "^".padLeft(col + 3 + offset, "-");
  }
}
