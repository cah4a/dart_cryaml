# CrYAML

Turing-complete YAML on steroids.

![CircleCI](https://img.shields.io/circleci/build/github/cah4a/dart_cryaml)
[![codecov](https://codecov.io/gh/cah4a/dart_cryaml/branch/master/graph/badge.svg)](https://codecov.io/gh/cah4a/dart_cryaml)


# Dart API

Load only data with variables:

```cryaml
name: "John"
count: $count
```

```dart
final cryaml = loadCrYAML(source);

final data = cryaml.evaluate({"count": 1}); // {"name": "John", count: 1}
```

Use functions inside document:

```cryaml
user:
  name: "John"
  count: multiply($count, times: 3)
```

```dart
final cryaml = loadCrYAML(source, Specification(
  functions: {
    "multiply": (int count, {int times: 1}) => count * times,
  }),
);

final data = cryaml.evaluate({"count": 1}); // {"name": "John", count: 2}
```

Use directives:

```cryaml
@user
  name: "John"
  count: multiply($count, times: 3)
```

```dart
class UserDirective extends Directive {
  final specification = const DirectiveSpec(
    documentType: DocumentType.map,
  );

  User call(CrYAMLContext context, {Map document()}) {
    final result = document();

    return User(
      name: result["name"],
      count: result["count"],
    );
  }
}

final cryaml = loadCrYAML(
  source,
  Specification(
    functions: {
      "multiply": (int count, {int times: 1}) => count * times,
    },
    directives: {"user": UserDirective()},
  ),
);

final data = cryaml.evaluate({"count": 1}); // {"name": "John", count: 2}
```