import 'dart:io';

import 'package:ab_dsl_interpreter/analyze/dsl_tool.dart';
import 'package:dart_casing/dart_casing.dart';

import '../analyze/dsl_entity.dart';
import '../dsl_constant.dart';

class DSLToIos {
  final UseCaseEntity entry;

  DSLToIos({
    required this.entry,
  });

  String outDir = '${DslConstant.workspaceDir}/ios';

  void generate() {
    Directory(outDir).createSync();

    List<String> methods = _makeMethods();
    Map context = {
      'name': DslConstant.pluginName,
      'methods': methods.join('\n'),
    };

    String templateFilePath = '${DslConstant.templateDir}/ios_plugin.temp';
    String iosFileName = Casing.pascalCase(DslConstant.pluginName);
    String targetFilePath = '$outDir/${iosFileName}Plugin.m';
    DSLTooL.renderFile(templateFilePath, context, targetFilePath);
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

        String methodStr = '''
- (void)${method.methodName}:(nullable id)arguments result:(FlutterResult)result {
   // do method implementation
}
        ''';
        methods.add(methodStr);
      }
    }
    return methods;
  }
}
