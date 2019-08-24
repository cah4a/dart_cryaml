import 'package:cryaml/cryaml.dart';
import 'package:test/test.dart';

void main() {
  test('simple', () {
    final cryaml = loadCrYAML(
      [
        'foo: "1"',
        'bar: 3.14',
        'bar: 2',
        'baz: null',
      ].join("\n"),
      null,
    );

    expect(cryaml.evaluate({}), {
      "foo": "1",
      "bar": 2,
      "baz": null,
    });
  });

  test('variables', () {
    final cryaml = loadCrYAML(
      [
        r'foo: [1, 2, $var]',
        r'bar: 1 + 3'
      ].join("\n"),
      null,
    );

    expect(
      cryaml.evaluate({"var": 3}),
      {
        "foo": [1, 2, 3],
        "bar": 4,
      },
    );
  });

  test('lists', () {
    final cryaml = loadCrYAML(
      [
        r'- foo: 1',
        r'- foo: $var',
      ].join("\n"),
      null,
    );

    expect(
      cryaml.evaluate({"var": 3}),
      [
        {"foo": 1},
        {"foo": 3},
      ],
    );
  });
}
