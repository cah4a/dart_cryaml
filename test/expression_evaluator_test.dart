import 'dart:math';

import 'package:cryaml/src/expression_evaluator.dart';
import 'package:cryaml/src/expressions.dart';
import 'package:test/test.dart';

final operations = {
  '*': (l, r) => l * r,
  '/': (l, r) => l / r,
  '~/': (l, r) => l ~/ r,
  '%': (l, r) => l % r,
  '+': (l, r) => l + r,
  '-': (l, r) => l - r,
  '<<': (l, r) => l << r,
  '>>': (l, r) => l >> r,
  '<': (l, r) => l < r,
  '<=': (l, r) => l <= r,
  '>': (l, r) => l > r,
  '>=': (l, r) => l >= r,
  '==': (l, r) => l == r,
  '!=': (l, r) => l != r,
  '&': (l, r) => l & r,
  '^': (l, r) => l ^ r,
  '|': (l, r) => l | r,
};

void main() {
  test('LiteralExpression', () {
    final object = Object();
    final eval = createExpressionEvaluator({}, {});

    expect(
      eval(LiteralExpression<Object>(object)),
      object,
    );
  });

  test('InterpolateExpression', () {
    final eval = createExpressionEvaluator(
      {},
      {'var': "bar"},
    );

    expect(
      eval(InterpolateExpression([
        LiteralExpression<String>("foo"),
        VarExpression("var"),
        LiteralExpression<String>("baz"),
      ])),
      'foobarbaz',
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

  final random = Random();

  operations.forEach(
    (operation, func) => test('Binary $operation operation', () {
          final eval = createExpressionEvaluator({}, {});

          final l = random.nextInt(1000);
          final r = random.nextInt(1000);

          expect(
            eval(BinaryExpression(
              LiteralExpression<int>(l),
              operation,
              LiteralExpression<int>(r),
            )),
            func(l, r),
          );
        }),
  );

  test('Binary && operation', () {
    final eval = createExpressionEvaluator({}, {});

    final l = random.nextBool();
    final r = random.nextBool();

    expect(
      eval(BinaryExpression(
        LiteralExpression<bool>(l),
        '&&',
        LiteralExpression<bool>(r),
      )),
      l && r,
    );
  });

  test('Binary || operation', () {
    final eval = createExpressionEvaluator({}, {});

    final l = random.nextBool();
    final r = random.nextBool();

    expect(
      eval(BinaryExpression(
        LiteralExpression<bool>(l),
        '||',
        LiteralExpression<bool>(r),
      )),
      l || r,
    );
  });
}
