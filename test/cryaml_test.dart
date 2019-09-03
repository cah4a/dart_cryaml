import 'package:cryaml/cryaml.dart';
import 'package:cryaml/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('basic', () {
    test('expression', () {
      final cryaml = loadCrYAML(r"$int * 2");

      expect(
        cryaml.evaluate({"int": 3}),
        6,
      );
    });

    test('map', () {
      final cryaml = loadCrYAML(
        [
          'foo: "1"',
          'bar: 3.14',
          'bar: 2',
          'buz:',
          'baz: null',
        ].join("\n"),
      );

      expect(cryaml.evaluate({}), {
        "foo": "1",
        "bar": 2,
        "buz": null,
        "baz": null,
      });
    });

    test('array as key', () {
      final cryaml = loadCrYAML(
        [
          'foo: [1, 2, \$var]',
        ].join("\n"),
      );

      expect(
        cryaml.evaluate({"var": 3}),
        {
          "foo": [1, 2, 3],
        },
      );
    });

    test('nested maps', () {
      final cryaml = loadCrYAML(
        [
          'test:',
          '  key:',
          '    bar: 1',
          '    baz: 2',
          '',
          'buz:',
          '  baz: null',
        ].join("\n"),
      );

      expect(cryaml.evaluate({}), {
        "test": {
          "key": {
            "bar": 1,
            "baz": 2,
          }
        },
        "buz": {
          "baz": null,
        }
      });
    });

    test('variables', () {
      final cryaml = loadCrYAML(
        [r'foo: [1, 2, $var]', r'bar: 1 + 3'].join("\n"),
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
          r'- foo:',
          r'',
          '\t\t ',
          r' ',
          r'- foo: $var',
        ].join("\n"),
      );

      expect(
        cryaml.evaluate({"var": 3}),
        [
          {"foo": null},
          {"foo": 3},
        ],
      );
    });
  });

  group('functions', () {
    test('no arguments', () {
      final object = Object();

      final specification = Specification(
        functions: {
          "object": () => object,
        },
      );

      final cryaml = loadCrYAML(
        r'object()',
        specification,
      );

      expect(
        cryaml.evaluate({}),
        object,
      );
    });

    test('positional', () {
      final specification = Specification(
        functions: {
          "multiply": (int value) => value * 2,
        },
      );

      final cryaml = loadCrYAML(
        r'multiply($var)',
        specification,
      );

      expect(
        cryaml.evaluate({"var": 3}),
        6,
      );
    });

    test('named', () {
      final specification = Specification(
        functions: {
          "multiply": ({int value}) => value * 2,
        },
      );

      final cryaml = loadCrYAML(
        r'multiply(value: $var)',
        specification,
      );

      expect(
        cryaml.evaluate({"var": 3}),
        6,
      );
    });
  });

  group('directives', () {
    test('simple', () {
      final object = Object();

      final specification = Specification(
        directives: {
          "foobar": _CrYAMLDirective(
            const DirectiveSpec(),
            (ctx) => object,
          ),
        },
      );

      final cryaml = loadCrYAML(
        r'@foobar',
        specification,
      );

      expect(
        cryaml.evaluate({}),
        object,
      );
    });

    test('expression document', () {
      final specification = Specification(
        directives: {
          "foobar": _CrYAMLDirective(
            const DirectiveSpec(documentType: DocumentType.any),
            (ctx, {document()}) => document(),
          ),
        },
      );

      final cryaml = loadCrYAML(
        [
          r'@foobar',
          r'  3 + 5',
        ].join("\n"),
        specification,
      );

      expect(
        cryaml.evaluate({}),
        8,
      );
    });

    test('directive as key value', () {
      final object = Object();

      final specification = Specification(
        directives: {
          "foobar": _CrYAMLDirective(
            const DirectiveSpec(),
            (ctx) => object,
          ),
        },
      );

      final cryaml = loadCrYAML(
        [
          r'key:',
          r'  foo: @foobar',
          r'  bar: @foobar',
          r'    nested: [1, 2, $var]',
          r'  other: "bar"',
        ].join("\n"),
        specification,
      );

      expect(
        cryaml.evaluate({}),
        {
          "key": {
            "foo": object,
            "bar": object,
            "other": "bar",
          },
        },
      );
    });

    test('arguments', () {
      final specification = Specification(
        directives: {
          "foobar": _CrYAMLDirective(
            const DirectiveSpec(arguments: [ArgumentType.expression]),
            (ctx, int value) => value * 2,
          ),
        },
      );

      final cryaml = loadCrYAML(
        r'@foobar $var',
        specification,
      );

      expect(
        cryaml.evaluate({"var": 3}),
        6,
      );
    });

    test('arguments with doc', () {
      final specification = Specification(
        directives: {
          "foobar": _CrYAMLDirective(
            const DirectiveSpec(
              arguments: [ArgumentType.expression],
              documentType: DocumentType.map,
            ),
            (CrYAMLContext ctx, String argument,
                    {Map document([CrYAMLContext context])}) =>
                document()["param"] + argument,
          ),
        },
      );

      final cryaml = loadCrYAML(
        [
          r'@foobar $var',
          r'  param: "foo"',
        ].join("\n"),
        specification,
      );

      expect(
        cryaml.evaluate({"var": "bar"}),
        "foobar",
      );
    });

    test('children', () {
      final o1 = Object();
      final o2 = Object();

      final specification = Specification(
        directives: {
          "bind": _CrYAMLDirective(
            const DirectiveSpec(
              arguments: [ArgumentType.declaration],
              childrenType: ChildrenType.list,
            ),
            (CrYAMLContext ctx, String name,
                {List children(CrYAMLContext context)}) {
              return children(ctx.withVariable(name, o2));
            },
          ),
          "o1": _CrYAMLDirective(
            const DirectiveSpec(),
            (ctx) => o1,
          ),
          "o2": _CrYAMLDirective(
            const DirectiveSpec(
              arguments: [ArgumentType.expression],
            ),
            (ctx, object) => object,
          ),
        },
      );

      final cryaml = loadCrYAML(
        [
          r'@bind $object',
          r'  @o1',
          r'  @o2 $object',
        ].join("\n"),
        specification,
      );

      expect(
        cryaml.evaluate({}),
        [
          o1,
          o2,
        ],
      );
    });
  });

  group('errors', () {
    final sources = {
      "expressions": "\$int * 2\n2+2",
      "documents": "foo: bar\n- list",
    };

    sources.forEach((type, source) {
      test('several $type', () {
        expect(
          () => loadCrYAML(source),
          throwsA(TypeMatcher<FormatException>()),
        );
      });
    });

    test("wrong directive call method", () {
      final spec = Specification(
        directives: {
          "foobar": _CrYAMLDirective(
            DirectiveSpec(arguments: [ArgumentType.expression]),
            () => null,
          ),
        },
      );

      expect(
        () => loadCrYAML("@foobar 2", spec).evaluate({}),
        throwsA(
          TypeMatcher<CrYAMLEvaluateException>().having(
            (e) => e.message,
            "message",
            "_CrYAMLDirective should implement call(CrYAMLContext context, arg0) method",
          ),
        ),
      );
    });
  });
}

class _CrYAMLDirective extends Directive {
  final Function call;

  _CrYAMLDirective(DirectiveSpec specification, this.call)
      : super(specification);
}
