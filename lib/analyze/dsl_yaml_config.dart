import 'dart:io';

import 'package:yaml/yaml.dart';

import './dsl_entity.dart';
import '../dsl_constant.dart';

void readYamlFile(String path) {
  File file = File(path);
  if (file.existsSync()) {
    String content = file.readAsStringSync();
    YamlMap mapInfo = loadYaml(content);
    DslConstant.configure = Configure.fromJson(mapInfo);
  }
}
