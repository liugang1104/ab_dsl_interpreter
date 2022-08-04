import 'analyzer.dart';
import 'dsl_annotation.dart';
import 'dsl_comment.dart';

extension FieldDeclarationImplUtils on FieldDeclarationImpl {
  Map translateToJson() {
    Map propertyUnitMap = Map();
    Map annotation = {};
    List comments = [];
    for (var child in this.childEntities.whereType<AnnotationImpl>()) {
      annotation.addAll(child.translateToJson());
    }

    for (final node in childEntities.whereType<CommentImpl>()) {
      comments = node.translateToJson();
    }

    for (var node in this.childEntities) {
      if (node is VariableDeclarationListImpl) {
        propertyUnitMap = _process(node, annotation, comments);
      }
    }
    return propertyUnitMap;
  }

  Map _process(
      VariableDeclarationListImpl node, Map annotation, List comments) {
    String _type = '';
    String _name = '';
    for (var child in node.childEntities) {
      if (child is NamedTypeImpl) {
        _type = child.toString();
      }
      if (child is VariableDeclarationImpl) {
        _name = child.name.toString();
      }
    }
    return {
      _name: {
        "name": _name,
        "type": _type,
        "annotation": annotation,
        "comments": comments
      }
    };
  }
}
