import 'package:collection/collection.dart';

final leq = ListEquality().equals;
final meq = MapEquality().equals;

List<int> lineAndColumnOf(String buffer, int position) {
  assert(position <= buffer.length);
  int line = 0;
  int pos = 0;
  while (true) {
    line++;
    final nextPos = buffer.indexOf("\n", pos + 1);

    if (nextPos > position || nextPos == -1) {
      return [line, position - pos + 1];
    }

    pos = nextPos;
  }
}