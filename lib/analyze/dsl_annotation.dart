import 'analyzer.dart';

extension AnnotationImplUtils on AnnotationImpl {
  Map translateToJson() {
    Map annotation = {};
    var annotationName = name.toString();
    if (annotationName == "Deprecated") {
      if (arguments is ArgumentListImpl) {
        NodeList<Expression> argumentsList = arguments!.arguments;
        for (var item in argumentsList) {
          if (item is SimpleStringLiteralImpl) {
            annotation["deprecated"] = item.stringValue ?? '';
            break;
          }
        }
      }
    } else {
      if (arguments is ArgumentListImpl) {
        NodeList<Expression> argumentsList = arguments!.arguments;
        for (var item in argumentsList) {
          var itemNameEx = item;
          if (itemNameEx is NamedExpressionImpl) {
            String name = itemNameEx.name.toString().replaceAll(":", "");
            var itemExpression = itemNameEx.expression;
            if (itemExpression is SimpleStringLiteralImpl) {
              annotation[name] = itemExpression.stringValue ?? '';
            } else if (itemExpression is BooleanLiteralImpl) {
              annotation[name] = itemExpression.value;
            } else if (itemExpression is ListLiteralImpl) {
              ListLiteralImpl itemEx = itemExpression;
              List listValues = [];
              itemEx.elements.forEach((element) {
                if (element is SimpleStringLiteralImpl) {
                  listValues.add(element.stringValue);
                } else if (element is PrefixedIdentifierImpl) {
                  PrefixedIdentifierImpl t = element;
                  listValues.add(t.identifier.toString());
                }
              });
              annotation[name] = listValues;
            } else if (itemExpression is SetOrMapLiteralImpl) {
              Map map = {};
              SetOrMapLiteralImpl tem = itemExpression;
              tem.becomeMap();
              tem.elements.forEach((element) {
                if (element is MapLiteralEntryImpl) {
                  String key = '';
                  String value = '';
                  if (element.key is SimpleStringLiteralImpl) {
                    key = (element.key as SimpleStringLiteralImpl).value;
                  }
                  if (element.value is SimpleStringLiteralImpl) {
                    value = (element.value as SimpleStringLiteralImpl).value;
                  }
                  map[key] = value;
                }
              });
              annotation[name] = map;
            } else if (itemExpression is MethodInvocationImpl) {
              MethodInvocationImpl itemEx = itemExpression;
              Map mapMethod = {};
              itemEx.argumentList.arguments.forEach((element) {
                NamedExpressionImpl nameEx = element as NamedExpressionImpl;
                String argName = nameEx.name.toString().replaceAll(":", "");
                var argEx = nameEx.expression;
                if (argEx is SimpleStringLiteralImpl) {
                  mapMethod[argName] = argEx.stringValue ?? '';
                } else if (argEx is SimpleIdentifierImpl) {
                  mapMethod[argName] = argEx.name;
                }
              });
              annotation[name] = mapMethod;
            }
          }
        }
      }
    }
    return annotation;
  }
}
