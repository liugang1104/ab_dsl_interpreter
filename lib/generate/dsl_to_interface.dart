import 'dart:io';

import 'package:ab_dsl_interpreter/analyze/dsl_entity.dart';
import 'package:ab_dsl_interpreter/analyze/dsl_tool.dart';
import 'package:ab_dsl_interpreter/dsl_constant.dart';
import 'package:ab_dsl_interpreter/generate/tool.dart';

class DSLToInterface with Tool {
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
          'castType': '<${method.castType}>',
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
    return "return ${createFactory(returnKey, returnType)};";
  }
}
