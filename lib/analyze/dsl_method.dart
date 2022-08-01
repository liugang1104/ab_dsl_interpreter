import 'analyzer.dart';
import 'dsl_annotation.dart';
import 'dsl_callback.dart';
import 'dsl_class.dart';

extension MethodDeclarationImplUtils on MethodDeclarationImpl {
  Map translateToJson() {
    List<Map> arguments = [];
    if (parameters is FormalParameterListImpl) {
      FormalParameterListImpl impl = parameters!;
      arguments = impl.translateToJson();
    }

    Map annotationMap = {};
    for (var child in childEntities.whereType<AnnotationImpl>()) {
      annotationMap.addAll(child.translateToJson());
    }

    List<String> list = getTuYaNullFlag(returnType.toString());
    return {
      "returnType": list[0],
      "nullFlag": list[1],
      "methodName": name.name,
      "init": annotationMap['init'] ?? false,
      "onlyInit": annotationMap['onlyInit'] ?? false,
      "argReplace": annotationMap['argReplace'],
      "deprecated": getDeprecated(annotationMap),
      "exception": getException(annotationMap),
      "isStatic": (modifierKeyword.toString() == "static" ? true : false),
      "arguments": arguments,
      "annotation": annotationMap,
      "annotationCh": annotationMap["annotationCh"] ?? {},
      "annotationEn": annotationMap["annotationEn"] ?? {},
      "supportPlatforms": annotationMap["supportPlatforms"] ?? [],
      "callbackParam": annotationMap["callbackParam"] ?? {}
    };
  }
}

Map getException(Map annotationMap) {
  //提取注释中的exception注释，放到method的类成员中
  Map exception = {};
  if (annotationMap["annotationEn"] != null &&
      annotationMap["annotationEn"]["exception"] != null) {
    exception = annotationMap["annotationEn"]["exception"];
  } else if (annotationMap["annotationCh"] != null &&
      annotationMap["annotationCh"]["exception"] != null) {
    exception = annotationMap["annotationCh"]["exception"];
  }
  return exception;
}

List<String> getTuYaNullFlag(String type) {
  List<String> listResult = [];
  String nullFlag = "";
  if (type == null || type.isEmpty) {
    type == "void";
  } else {
    if (type.startsWith("TuyaNonNull") || type.startsWith("TuyaNullable")) {
      if (type.startsWith("TuyaNonNull")) {
        nullFlag = "NonNull";
      } else {
        nullFlag = "Nullable";
      }
      type = type.split("<").last.split(">").first.trim();
    }
  }

  listResult.add(type);
  listResult.add(nullFlag);

  return listResult;
}
