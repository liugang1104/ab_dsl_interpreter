import '../dsl_constant.dart';

mixin Tool {
  String createFactory(String key, dynamic value,
      {bool isRegressionWithKey = false}) {
    if (DslConstant.enumNameList.contains(value)) {
      return "${value}Map[${isRegressionWithKey ? key : "json['$key']"}]";
    } else if (baseTypes.contains(value)) {
      // 基础类型
      return "$key ?? ${defaultValue[value]}";
    } else if (value is String && value.trim().startsWith('List<')) {
      final String dartType = value.trim();
      return "($key ?? []).map((element) => ${createFactory(
        'element',
        dartType
            .substring(dartType.indexOf("<") + 1, dartType.lastIndexOf(">"))
            .trim(),
        isRegressionWithKey: true,
      )}).toList()";
    } else if (value is String && value.trim().startsWith('Map<')) {
      final String dartType = value.trim();
      final int firstLeftQuarterIndex = dartType.indexOf("<");

      ///语法解析，获得map的key和value
      int wrapSymbolCount = 0;
      int index = firstLeftQuarterIndex + 1;
      int commaIndex = 0;
      while (index < dartType.length) {
        if (dartType[index] == "<") {
          wrapSymbolCount++;
        } else if (dartType[index] == ">") {
          wrapSymbolCount--;
        } else if (dartType[index] == ",") {
          if (wrapSymbolCount == 0) {
            commaIndex = index;
            break;
          }
        }
        index++;
      }

      final String mapKeyType =
          dartType.substring(firstLeftQuarterIndex + 1, commaIndex).trim();
      final String mapValueType =
          dartType.substring(commaIndex + 1, dartType.lastIndexOf(">")).trim();
      return "($key ?? {}).map((key, element) => MapEntry(${createFactory('key', mapKeyType, isRegressionWithKey: true)}, ${createFactory('element', mapValueType, isRegressionWithKey: true)}))";
    }
    // 只剩下可序列化的对象
    return "$value.fromJson(res ?? {})";
  }
}
