import 'dart:convert';

import 'analyzer.dart';

extension EnumDeclarationImplUtils on EnumDeclarationImpl {
  Map translateToJson() {
    return {
      'plainString': this.toString(),
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
