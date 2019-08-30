library cryaml;

import 'package:cryaml/src/context.dart';
import 'package:cryaml/src/parser.dart';
import 'package:cryaml/src/specification.dart';
import 'package:cryaml/src/tokenizer.dart';

export 'package:cryaml/src/context.dart';
export 'package:cryaml/src/specification.dart';

CrYAMLDocument loadCrYAML(String source, [Specification specification]) {
  final tokens = Tokenizer().tokenize(source).toList();
  final intermediate = Parser().parse(tokens, source: source);
  return _CrYAMLDocument(
    specification ?? const Specification(),
    intermediate,
  );
}

abstract class CrYAMLDocument {
  dynamic evaluate([Map<String, dynamic> variables = const {}]);
}

class _CrYAMLDocument extends CrYAMLDocument {
  final Specification specification;
  final dynamic intermediate;

  _CrYAMLDocument(this.specification, this.intermediate);

  dynamic evaluate([Map<String, dynamic> variables = const {}]) {
    return CrYAMLContext(specification, variables).eval(intermediate);
  }
}
