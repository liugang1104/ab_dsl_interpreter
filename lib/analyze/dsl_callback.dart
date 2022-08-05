import 'analyzer.dart';
import 'dsl_tool.dart';

extension GenericTypeAliasImplUtils on GenericTypeAliasImpl {
  Map translateToJson() {
    String returnType = "";
    List<Map> arguments = [];
    if (functionType is GenericFunctionTypeImpl) {
      // todo: 做了强转
      GenericFunctionTypeImpl _functionType =
          functionType as GenericFunctionTypeImpl;
      Map data = _functionType.translateToJson();
      returnType = data["returnType"];
      arguments = data["arguments"];
    }
    if (returnType == "") returnType = "void";
    return {
      "methodName": this.name.name,
      "returnType": returnType,
      "arguments": arguments
    };
  }
}

extension FormalParameterListImplUtils on FormalParameterListImpl {
  List<Map> translateToJson() {
    List<Map> arguments = [];
    int idx = 1;
    Map callbackMap = {};
    for (FormalParameter parameter in parameters) {
      if (parameter is SimpleFormalParameterImpl) {
        String type = '';
        String name = parameter.identifier.toString();
        if (parameter.type is NamedTypeImpl) {
          type = parameter.type.toString();
        } else if (parameter.type is GenericFunctionTypeImpl) {
          GenericFunctionTypeImpl functionTypeImpl =
              parameter.type as GenericFunctionTypeImpl;
          String callbackName = name.capitalize();
          type = callbackInMethodTypeName(callbackName);
          callbackMap = functionTypeImpl.translateToJson();
          callbackMap["methodName"] = type;
          // callbackListInMethod.add(callbackMap);
        }
        if (name == 'null') {
          name = 'arg$idx';
        }
        Map map = {"type": type, "name": name, 'callbackMap': callbackMap};
        arguments.add(map);
        idx += 1;
      }
    }
    return arguments;
  }

  String callbackInMethodTypeName(String baseName) {
    String callbackName = baseName;
    AstNode node = this;
    while (node.parent != null) {
      if (node is MethodDeclarationImpl) {
        String methodName = node.name.name;
        callbackName = methodName.capitalize() + callbackName;
      } else if (node is ClassDeclarationImpl) {
        String className = node.name.name;
        callbackName = className.capitalize() + callbackName;
      }
      node = node.parent!;
    }
    return callbackName;
  }
}

extension GenericFunctionTypeImplUtils on GenericFunctionTypeImpl {
  Map translateToJson() {
    String returnType = "";
    List<Map> arguments = [];
    // if (this.returnType is TypeNameImpl) {
    //   returnType = this.returnType.toString();
    // }
    // if (this.parameters is FormalParameterListImpl) {
    //   FormalParameterListImpl _parameterListImpl = this.parameters;
    //   arguments = _parameterListImpl.translateToJson();
    //   if (arguments.length == 1) {
    //     if (arguments.first['type'] == 'void') {
    //       arguments.removeLast();
    //     }
    //   }
    // }
    if (returnType == "") {
      returnType = "void";
    }
    return {"returnType": returnType, "arguments": arguments};
  }
}
