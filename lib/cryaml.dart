library cryaml;

import 'package:cryaml/src/directive_declarations.dart';
import 'package:cryaml/src/executor.dart';
import 'package:cryaml/src/parser.dart';
import 'package:cryaml/src/tokenizer.dart';

CrYAMLDocument loadCrYAML(String source, CrYAMLDeclarations declarations) {
  final tokens = Tokenizer().tokenize(source);
  final intermediate = Parser().parse(tokens);
  return CrYAMLDocument(intermediate);
}

class CrYAMLDocument {
  final dynamic intermediate;

  CrYAMLDocument(this.intermediate);

  dynamic evaluate(Map<String, dynamic> variables) {
    return CrYAMLContext(variables).eval(intermediate);
  }
}
