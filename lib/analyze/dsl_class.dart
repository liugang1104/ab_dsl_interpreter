import 'analyzer.dart';
import 'dsl_annotation.dart';
import 'dsl_field.dart';
import 'dsl_method.dart';

extension ClauseDeclarationImplUtils on ClassDeclarationImpl {
  Map translateToJson() {
    List<Map> members = [];
    List<Map> methods = [];
    Map annotationMap = {};
    Map annotation = {};
    Map propertyMap = {};
    for (final child in childEntities.whereType<FieldDeclarationImpl>()) {
      members.add(child.translateToJson());
      Map propertyUnitMap = child.translateToJson();
      propertyMap.addEntries(propertyUnitMap.entries);
    }
    for (final child in childEntities.whereType<MethodDeclarationImpl>()) {
      Map map = child.translateToJson();
      methods.add(map);
    }
    for (var child in childEntities.whereType<AnnotationImpl>()) {
      annotation.addAll(child.translateToJson());
      annotationMap.addAll(child.translateToJson());
    }

    bool isAbstract = false;
    if (abstractKeyword.toString() == "abstract") {
      isAbstract = true;
    }

    Map classMap = {};
    classMap['plainString'] = this.toString();
    classMap["className"] = name.name;
    classMap['superClass'] = extendsClause?.superclass.name.name;
    classMap["supportPlatforms"] = annotationMap["supportPlatforms"] ?? [];
    classMap["deprecated"] = getDeprecated(annotationMap);
    classMap["isAbstract"] = isAbstract;
    classMap["memberVariables"] = members;
    classMap["properties"] = propertyMap;
    classMap["methods"] = methods;
    classMap["annotation"] = annotation;
    annotationMap.forEach((key, value) {
      if (classMap.containsKey(key) == false) {
        classMap[key] = value;
      }
    });
    return classMap;
  }
}

String getDeprecated(Map annotationMap) {
  //提取注释中的deprecated注释
  String annotationDeprecated = "";
  if (annotationMap["annotationEn"] != null &&
      annotationMap["annotationEn"]["deprecated"] != null &&
      annotationMap["annotationEn"]["deprecated"].toString().isNotEmpty) {
    annotationDeprecated = annotationMap["annotationEn"]["deprecated"];
  } else if (annotationMap["annotationCh"] != null &&
      annotationMap["annotationCh"]["deprecated"] != null &&
      annotationMap["annotationCh"]["deprecated"].toString().isNotEmpty) {
    annotationDeprecated = annotationMap["annotationCh"]["deprecated"];
  }
  return annotationDeprecated;
}
