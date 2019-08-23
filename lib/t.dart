import 'dart:io';
import 'package:yaml/yaml.dart';

void main(){
  var res = loadYaml(File("./t.yaml").readAsStringSync());
  print(res.runtimeType);
  print(res);
}