import 'dart:io';

import 'package:ab_dsl_interpreter/analyze/dsl_tool.dart';

import '../analyze/dsl_entity.dart';
import '../dsl_constant.dart';

void generate(UseCaseEntity entity) {
  String outDir = '${DslConstant.workspaceDir}/ios';
  Directory(outDir).createSync();

  Map context = {
    'date': DSLTooL.dateStr(),
    'name': DslConstant.pascalPluginName,
  };

  String templatePath = '${DslConstant.templateDir}/ios/plugin.m.temp';
  String targetPath = '$outDir/${DslConstant.pascalPluginName}Plugin.m';
  DSLTooL.renderFile(templatePath, context, targetPath);

  // 将生成的文件拷贝到plugin目录
  String newPath =
      '${DslConstant.iosScrDir}/${DslConstant.pascalPluginName}Plugin.m';
  File(targetPath).copy(newPath);
}
