import 'dart:convert';

import 'analyzer.dart';
import 'dsl_annotation.dart';

extension EnumDeclarationImplUtils on EnumDeclarationImpl {
  Map translateToJson() {
    final _name = this.name.toString();
    List<Map> eunmList = [];
    List customEnumList = [];
    for (var item in this.constants.whereType<EnumConstantDeclarationImpl>()) {
      Map data = Map();
      String name = item.name.toString();
      String value = this.constants.indexOf(item).toString();
      Map unitAnnotation = {"info": "", "detail": {}};
      for (var child in item.childEntities.whereType<AnnotationImpl>()) {
        unitAnnotation = child.translateToJson();
        break;
      }
      data["name"] = name;
      data["value"] = value;
      data["annotation"] = unitAnnotation;
      data["annotationCh"] = unitAnnotation["annotationCh"] ?? {};
      data["annotationEn"] = unitAnnotation["annotationEn"] ?? {};
      eunmList.add(data);
    }
    Map annotation = {};
    for (var child in this.childEntities.whereType<AnnotationImpl>()) {
      if (child is AnnotationImpl) {
        // if (child.name.toString() == "TYLabelAnnotation") {
        annotation.addAll(child.translateToJson());
        // }
      }
    }

    for (var node in this.childEntities.whereType<AnnotationImpl>()) {
      customEnumList = customEnum(node, _name);
      if (customEnumList.length > 0) break;
    }

    eunmList.forEach((old) {
      customEnumList.forEach((custom) {
        if (custom["name"] == old["name"]) old["value"] = custom["value"];
      });
    });

    return {
      "name": _name,
      "supportPlatforms": annotation["supportPlatforms"] ?? [],
      "enumList": eunmList,
      "annotation": annotation,
      "isCustomValue": customEnumList.length > 0,
      "annotationCh": annotation["annotationCh"] ?? {},
      "annotationEn": annotation["annotationEn"] ?? {},
    };
  }

  List customEnum(AnnotationImpl node, String name) {
    String enumMapStr = "";
    List enumList = [];

    if (node.name.toString() == "TYCustomEnumValue") {
      ArgumentListImpl arguments = node.arguments!;
      NodeList<Expression> argumentsList = arguments.arguments;
      for (AstNode node in argumentsList) {
        if (node is SetOrMapLiteralImpl) {
          enumMapStr = node.toString();
        }
      }
    }

    if (name.length > 0 && enumMapStr.length > 0) {
      Map enumMap = json.decode(enumMapStr);
      enumMap.forEach((key, value) {
        Map data = Map();
        data["name"] = key;
        data["value"] = value.toString();
        enumList.add(data);
      });
    }
    return enumList;
  }
}
