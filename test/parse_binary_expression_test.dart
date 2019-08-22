import 'package:cryaml/src/expressions.dart';
import 'package:cryaml/src/expression_parser.dart';
import 'package:test/test.dart';

final A = VarExpression("A");
final B = VarExpression("B");
final C = VarExpression("C");

main() {
  test("plus", () {
    expect(
      parseExpression([A, "+", B, "+", C]),
      BinaryExpression(
        BinaryExpression(A, "+", B),
        "+",
        C,
      ),
    );
  });

  test("multiply", () {
    expect(
      parseExpression([A, "+", B, "*", C]),
      BinaryExpression(
        A,
        "+",
        BinaryExpression(B, "*", C),
      ),
    );
  });

  test("complex", () {
    expect(
      parseExpression([A, "+", B, "*", C, "/", A, "+", C]),
      BinaryExpression(
        BinaryExpression(
          A,
          "+",
          BinaryExpression(
            BinaryExpression(B, "*", C),
            "/",
            A,
          ),
        ),
        "+",
        C,
      ),
    );
  });
}
