import 'package:cryaml/src/expression_evaluator.dart';
import 'package:cryaml/src/expressions.dart';
import 'package:test/test.dart';

void main() {
  test('LiteralExpression', () {
    final object = Object();
    final eval = createExpressionEvaluator({}, {});

    expect(
      eval(LiteralExpression<Object>(object)),
      object,
    );
  });

  test('VarExpression', () {
    final object = Object();
    final eval = createExpressionEvaluator({}, {"foo": object});

    expect(
      eval(VarExpression("foo")),
      object,
    );
  });

  test('BinaryExpression', () {
    final eval = createExpressionEvaluator({}, {});

    expect(
      eval(
        BinaryExpression(
          LiteralExpression<int>(1),
          "+",
          BinaryExpression(
            LiteralExpression<int>(2),
            "|",
            LiteralExpression<int>(4),
          ),
        ),
      ),
      7,
    );
  });

  test('CallExpression empty params', () {
    final object = Object();
    final eval = createExpressionEvaluator(
      {
        "foo": () => object,
      },
      {},
    );

    expect(
      eval(CallExpression("foo")),
      object,
    );
  });

  test('CallExpression with positioned params', () {
    final object = Object();
    final eval = createExpressionEvaluator(
      {
        "foo": (arg) => arg,
      },
      {
        "var": object,
      },
    );

    expect(
      eval(CallExpression("foo", [VarExpression("var")])),
      object,
    );
  });

  test('CallExpression with named params', () {
    final object = Object();
    final eval = createExpressionEvaluator(
      {
        "foo": ({Object arg}) => arg,
      },
      {
        "var": object,
      },
    );

    expect(
      eval(CallExpression("foo", [], {"arg": VarExpression("var")})),
      object,
    );
  });

  test('ArrayExpression', () {
    final object = Object();
    final eval = createExpressionEvaluator({}, {"var": object});

    expect(
      eval(ArrayExpression([
        LiteralExpression<int>(1),
        LiteralExpression<double>(1.2),
        VarExpression("var"),
      ])),
      [1, 1.2, object],
    );
  });
}
