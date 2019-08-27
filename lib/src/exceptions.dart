class CrYAMLEvaluateException implements Exception {
  final message;

  CrYAMLEvaluateException(this.message);

  String toString() => "CrYAMLEvaluateException: $message";
}
