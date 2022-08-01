import 'dart:io';

import 'package:ab_dsl_interpreter/analyze/dsl_tool.dart';
import 'package:ab_dsl_interpreter/dsl_constant.dart';

import '../analyze/dsl_entity.dart';

/// plugn入口文件生成

class DSLToEntrance {
  final UseCaseEntity entry;

  DSLToEntrance({required this.entry});

  void generate() {
    String outDir = '${DslConstant.workspaceDir}/${DslConstant.pluginName}';
    Directory(outDir).createSync();

    String templateFilePath = '${DslConstant.templateDir}/package.temp';
    String targetFilePath = '$outDir/${DslConstant.pluginName}.dart';

    List<String> methods = _makeMethods();

    Map context = {
      'name': DslConstant.pluginName,
      'methods': methods.join('\n'),
    };
    DSLTooL.renderFile(templateFilePath, context, targetFilePath);

    // 将生成的文件拷贝到plugin目录
    String newPath =
        '${DslConstant.pluginPath}/${DslConstant.pluginName}/lib/${DslConstant.pluginName}.dart';
    File(targetFilePath).copy(newPath);
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
          'argsDef': method.argsDefine,
          'args': method.argsInput
        };
        String methodStr = DSLTooL.renderUnit(
            '${DslConstant.templateDir}/unit/entrance_method.temp', context);
        methods.add(methodStr);
      }
    }
    return methods;
  }
}
