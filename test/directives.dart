import 'package:cryaml/cryaml.dart';

class IfDirective implements Directive {
  final specification = DirectiveSpec(
    arguments: [ArgumentType.expression],
    documentType: DocumentType.any,
  );

  call(dynamic value, {document}) {
    if (value == true) {
      return document;
    }

    return null;
  }
}

class PersonDirective implements Directive {
  final specification = DirectiveSpec(
    arguments: [ArgumentType.declaration, ArgumentType.expression],
    documentType: DocumentType.map,
  );

  Person call(dynamic value, {Map document}) {
    return Person(
      name: document["name"],
      age: document["age"],
      birthdate: document["birthdate"],
      books: document["books"],
    );
  }

  CrYAMLContext getChildContext(
      CrYAMLContext context, String name, dynamic value) {
    return context.withVariable(name, value);
  }
}

class Person {
  final name;
  final age;
  final birthdate;
  final books;

  Person({this.name, this.age, this.birthdate, this.books});
}
