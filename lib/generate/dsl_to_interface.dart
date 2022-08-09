import 'dart:io';

import 'package:ab_dsl_interpreter/analyze/dsl_entity.dart';
import 'package:ab_dsl_interpreter/analyze/dsl_tool.dart';
import 'package:ab_dsl_interpreter/dsl_constant.dart';

class DSLToInterface {
  final UseCaseEntity entry;

  DSLToInterface({
    required this.entry,
  });

  String outDir = '${DslConstant.workspaceDir}/platform_interface';

  void generate() {
    Directory(outDir).createSync();

    _generatePlatformInterfaceFile();
    _generateMethodChannelFile();
  }

  /// 生成 xx_platform_interface.dart
  void _generatePlatformInterfaceFile() {
    List<String> exports = DslConstant.interfaceSrcFiles
        .map((e) =>
            'export \'package:${DslConstant.pluginName}_platform_interface/src/$e\';')
        .toList();

    Map context = {
      'plugin_name': DslConstant.pluginName,
      'exports': exports.join('\n')
    };

    String templatePath = '${DslConstant.templateDir}/platform_interface.temp';
    String outFilePath =
        '$outDir/${DslConstant.pluginName}_platform_interface.dart';
    DSLTooL.renderFile(templatePath, context, outFilePath);

    // 将生成的文件拷贝到plugin目录
    String newPath =
        '${DslConstant.pluginPath}/${DslConstant.pluginName}_platform_interface/lib/${DslConstant.pluginName}_platform_interface.dart';
    File(outFilePath).copy(newPath);
  }

  /// 生成 method_channel_xx.dart
  void _generateMethodChannelFile() {
    List<String> imports = DslConstant.interfaceSrcFiles
        .where((element) =>
            element != 'method_channel_${DslConstant.pluginName}.dart')
        .map((e) =>
            'import \'package:${DslConstant.pluginName}_platform_interface/src/$e\';')
        .toList();
    List<String> methods = _makeMethods();

    Map context = {
      'name': DslConstant.pluginName,
      'imports': imports.join('\n'),
      'methods': methods.join('\n')
    };

    String templatePath = '${DslConstant.templateDir}/method_channel.temp';
    String outFilePath =
        '$outDir/method_channel_${DslConstant.pluginName}.dart';
    DSLTooL.renderFile(templatePath, context, outFilePath);

    // 将生成的文件拷贝到plugin目录
    String newPath =
        '${DslConstant.pluginPath}/${DslConstant.pluginName}_platform_interface/lib/src/method_channel_${DslConstant.pluginName}.dart';
    File(outFilePath).copy(newPath);
  }

  List<String> _makeMethods() {
    List<String> methods = [];
    for (UseCaseClass cls in entry.classes) {
      // 可能存在其它Model类，抽象类才是需要解析的api,
      if (cls.superClass != 'PlatformInterface') {
        continue;
      }

      for (UseCaseMethod method in cls.methods) {
        if (method.methodName == 'instance') {
          continue;
        }

        Map context = {
          'returnType': method.returnType,
          'methodName': method.methodName,
          'castType': _makeCastType(method),
          'argsDef': method.argsDefine,
          'channelArgs': _makeChannelArgs(method),
          'returnStr': _makeReturnString(method),
        };
        String methodStr = DSLTooL.renderUnit(
            '${DslConstant.templateDir}/unit/method.temp', context);
        methods.add(methodStr);
      }
    }
    return methods;
  }

  // channel 返回值类型，obj类型转为map
  String _makeCastType(UseCaseMethod method) {
    if (method.isVoidReturnType) {
      return '';
    }
    if (DslConstant.baseTypes.contains(method.originReturnType)) {
      return '<${method.originReturnType}>';
    }
    if (method.originReturnType.startsWith('List<')) {
      String subType = method.originReturnType;
      subType = subType
          .substring(subType.indexOf("<") + 1, subType.lastIndexOf(">"))
          .trim();
      if (DslConstant.baseTypes.contains(subType)) {
        return '<${method.originReturnType}>';
      }
      return '<List<Map>>';
    }
    return '<Map<String, dynamic>>';
  }

  String _makeChannelArgs(UseCaseMethod method) {
    String str = "'${method.methodName}',";
    if (method.arguments.isEmpty) return str;
    List<String> pairs = ['\n          {'];
    for (ArgumentEntity element in method.arguments) {
      pairs.add('             \'${element.name}\': ${element.name},');
    }
    pairs.add('          }');
    str += pairs.join('\n');
    return str;
  }

  String _makeReturnString(UseCaseMethod method) {
    if (method.isVoidReturnType) {
      return 'return;';
    }
    String returnType = method.originReturnType;
    String returnKey = 'res';
    bool isOptional = method.returnType.isOptional;
    return "return ${createFactory(returnKey, returnType, isOptional: isOptional)};";
  }

  String createFactory(String key, dynamic value, {bool isOptional = false}) {
    // 基础类型
    if (DslConstant.baseTypes.contains(value)) {
      if (isOptional) {
        return '$key';
      }
      return "$key ?? ${DslConstant.defaultValue[value]}";
    } else if (value is String && value.trim().startsWith('List<')) {
      String subType = value.trim();
      subType = subType
          .substring(subType.indexOf("<") + 1, subType.lastIndexOf(">"))
          .trim();
      if (DslConstant.baseTypes.contains(subType)) {
        if (isOptional) {
          return '$key';
        } else {
          return '$key ?? []';
        }
      } else {
        return "($key ?? []).map((element) => ${createFactory(
          'element',
          subType,
          isOptional: true,
        )}).toList()";
      }
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
      return "($key ?? {}).map((key, element) => MapEntry(${createFactory('key', mapKeyType, isOptional: true)}, ${createFactory('element', mapValueType, isOptional: true)}))";
    }
    // 只剩下可序列化的对象
    return "$value.fromJson(${isOptional ? '$key' : '$key ?? {}'})";
  }
}
