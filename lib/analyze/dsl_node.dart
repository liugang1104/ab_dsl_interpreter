import 'analyzer.dart';
import 'dsl_callback.dart';
import 'dsl_class.dart';
import 'dsl_enum.dart';

List callbackListInMethod = [];

extension AstNodeUtils on AstNode {
  Map translateToJson(String filePath) {
    callbackListInMethod = [];
    Map data = {};
    List<Map> classMapList = [];
    List<String> dartImport = [];
    for (final node in root.childEntities.whereType<ImportDirectiveImpl>()) {
      String? import = node.uri.stringValue;
      if (import != null &&
          (import.contains("generate.package:") || import.contains("dart:"))) {
        continue;
      }
    }
    data["dart_import"] = dartImport;

    List enumList = [];
    for (final node in root.childEntities.whereType<EnumDeclarationImpl>()) {
      Map map = node.translateToJson();
      enumList.add(map);
    }
    data["enums"] = enumList;

    List callbackList = [];
    for (final node in root.childEntities.whereType<GenericTypeAliasImpl>()) {
      Map map = node.translateToJson();
      callbackList.add(map);
    }

    for (final node in root.childEntities.whereType<ClassDeclarationImpl>()) {
      Map classMap = node.translateToJson();
      classMapList.add(classMap);
    }
    data["classes"] = classMapList;
    callbackList.addAll(callbackListInMethod);
    data["callbacks"] = callbackList;

    return {
      filePath: data,
    };
  }
}
