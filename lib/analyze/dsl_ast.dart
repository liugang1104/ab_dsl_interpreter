import 'dart:convert';
import 'dart:io';

import 'package:ab_dsl_interpreter/dsl_constant.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;

import 'dsl_node.dart';

main(List<String> args) {
  generateJsonFile();
}

generateJsonFile() {
  Directory(DslConstant.dslJsonDir).createSync(recursive: true);

  final dslDir = Directory(
      '${DslConstant.pluginPath}/${DslConstant.pluginName}_platform_interface/lib/src');
  List<FileSystemEntity> dslDirList =
      dslDir.listSync(recursive: false, followLinks: false);

  List<String> fileNames = [];
  dslDirList.forEach((final file) {
    fileNames.add(path.basename(file.path));
    buildJsonFileFromDartFile(file.path, DslConstant.dslJsonDir);
  });
  DslConstant.interfaceSrcFiles = fileNames;
}

///read dart file ,extra dart info to Json and finally build json file
void buildJsonFileFromDartFile(String dartPath, String jsonPath) {
  final Map data = readDirectoryDartFiles(dartPath);
  writeDataToFile(data);
}

///read files under [directoryPath]
Map readDirectoryDartFiles(final String directoryPath) {
  final Map data = {};
  final Directory directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    File file = File(directoryPath);
    if (!file.existsSync()) {
      return {};
    }
    Map unitMap = readUnitDartFile(file);
    data.addEntries(unitMap.entries);
    return data;
  }
  final List<FileSystemEntity> dslDirList =
      directory.listSync(recursive: false, followLinks: false);
  dslDirList.forEach((final fileEntity) {
    String filePath = fileEntity.path;
    File file = File(filePath);
    if (file.existsSync()) {
      Map unitMap = readUnitDartFile(file);
      data.addEntries(unitMap.entries);
    }
  });
  return data;
}

///read [file] by [parseString]&[AstNodeUtils.translateToJson]
///return map contains json info of [file] and target json file temp path
Map readUnitDartFile(final File file) {
  if (!file.existsSync()) return {};
  final String content = file.readAsStringSync();
  ParseStringResult result = parseString(content: content);
  CompilationUnit unit = result.unit;
  final root = unit.root;
  String path = file.path.replaceAll(
      '${DslConstant.pluginName}_platform_interface/lib/src',
      'workspace/dsl_json');
  path = path.replaceFirst(".dart", ".json");
  Map data = root.translateToJson(path);
  return data;
}

///build json file
void writeDataToFile(final Map data) {
  data.forEach((filePath, jsonData) {
    String jsonString = json.encode(jsonData);
    File targetFile = File(filePath);
    targetFile.writeAsStringSync(jsonString);
  });
}
