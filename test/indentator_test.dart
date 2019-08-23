import 'package:cryaml/src/indentator.dart';
import 'package:cryaml/src/token.dart';
import 'package:test/test.dart';

void main() {
  Indentator indentator;

  setUp((){
    indentator = Indentator();
  });

  test("indentator", () {
    expect(
      indentator(0, null).toList(),
      [],
    );

    expect(
      indentator(3, null).toList(),
      [
        Indentation.indent,
      ],
    );

    expect(
      indentator(8, null).toList(),
      [
        Indentation.indent,
      ],
    );

    expect(
      indentator(0, null).toList(),
      [
        Indentation.dedent,
        Indentation.dedent,
      ],
    );
  });

  test("starts not from zero", () {
    expect(
      indentator(4, null).toList(),
      [],
    );

    expect(
      indentator(6, null).toList(),
      [Indentation.indent],
    );
  });

  test("indentator with list marks", () {
    expect(
      indentator(0, 2).toList(),
      [
        Indentation.listIndent,
      ],
    );

    expect(
      indentator(2, null).toList(),
      [],
    );

    expect(
      indentator(0, 2).toList(),
      [
        Indentation.listIndent,
      ],
    );

    expect(
      indentator(2, 4).toList(),
      [
        Indentation.indent,
        Indentation.listIndent,
      ],
    );

    expect(
      indentator(0, null).toList(),
      [
        Indentation.dedent,
      ],
    );
  });
}
