import 'package:test/test.dart';
import 'package:cryaml/src/utils.dart';

void main() {
  test('oneliner', () {
    expect(
      lineAndColumnOf("1233", 3),
      [1, 4],
    );
  });

  test('multiline', () {
    expect(
      lineAndColumnOf("1245\n\n\n6", 6),
      [4, 1],
    );
  });
}
