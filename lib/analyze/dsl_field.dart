import 'analyzer.dart';
import 'dsl_annotation.dart';

extension FieldDeclarationImplUtils on FieldDeclarationImpl {
  Map translateToJson() {
    Map propertyUnitMap = Map();
    Map annotation = {};
    for (var child in this.childEntities.whereType<AnnotationImpl>()) {
      if (child is AnnotationImpl) {
        annotation.addAll(child.translateToJson());
      }
    }
    for (var node in this.childEntities) {
      if (node is VariableDeclarationListImpl) {
        propertyUnitMap = _process(node, annotation);
      }
    }
    return propertyUnitMap;
  }

  Map _process(VariableDeclarationListImpl node, Map annotation) {
    String _type = '';
    String _name = '';
    for (var child in node.childEntities) {
      // if (child is TypeNameImpl) {
      //   _type = child.toString();
      // }
      if (child is VariableDeclarationImpl) {
        _name = child.name.toString();
      }
    }
    return {
      _name: {"type": _type, "annotation": annotation}
    };
  }
}
