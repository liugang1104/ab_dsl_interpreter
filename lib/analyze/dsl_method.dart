import 'analyzer.dart';
import 'dsl_annotation.dart';
import 'dsl_callback.dart';
import 'dsl_class.dart';
import 'dsl_comment.dart';

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

    List<String> comments = [];
    for (final node in childEntities.whereType<CommentImpl>()) {
      comments = node.translateToJson();
    }

    return {
      "originString": this.toString(),
      "returnType": returnType.toString(),
      "nullFlag": '',
      "methodName": name.name,
      "comments": comments,
      "deprecated": getDeprecated(annotationMap),
      "exception": getException(annotationMap),
      "isStatic": (modifierKeyword.toString() == "static" ? true : false),
      "arguments": arguments,
      "annotation": annotationMap,
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
