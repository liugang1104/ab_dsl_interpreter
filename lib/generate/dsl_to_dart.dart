import 'package:ab_dsl_interpreter/analyze/dsl_entity.dart';
import 'package:ab_dsl_interpreter/analyze/dsl_tool.dart';
import 'package:ab_dsl_interpreter/dsl_constant.dart';

void generate(UseCaseEntity entity) {
  _generatePlatformInterfaceFile();
  _generateMethodChannelFile();
  _generateAppFacingFile(entity);
}

/// 生成 interface export 文件
void _generatePlatformInterfaceFile() {
  List<String> exports = DslConstant.interfaceSrcFiles
      .map((e) =>
          'export \'package:${DslConstant.pluginName}_platform_interface/src/$e\';')
      .toList();

  Map context = {
    'plugin_name': DslConstant.pluginName,
    'exports': exports.join('\n')
  };

  String templatePath =
      '${DslConstant.templateDir}/dart/platform_interface.temp';
  String outFilePath =
      '${DslConstant.platformDir}/lib/${DslConstant.pluginName}_platform_interface.dart';
  DSLTooL.renderFile(templatePath, context, outFilePath);
}

/// 生成 method_channel_xx.dart
void _generateMethodChannelFile() {
  List<String> imports = DslConstant.interfaceSrcFiles
      .where((element) =>
          element != 'method_channel_${DslConstant.pluginName}.dart')
      .map((e) =>
          'import \'package:${DslConstant.pluginName}_platform_interface/src/$e\';')
      .toList();
  imports.add('import \'${DslConstant.pluginName}_pigeon.dart\';');

  Map context = {
    'name': DslConstant.pascalPluginName,
    'imports': imports.join('\n'),
  };

  String templatePath = '${DslConstant.templateDir}/dart/method_channel.temp';
  String outFilePath =
      '${DslConstant.platformDir}/lib/src/method_channel_${DslConstant.pluginName}.dart';
  DSLTooL.renderFile(templatePath, context, outFilePath);
}

/// 生成App - facing 文件
void _generateAppFacingFile(UseCaseEntity entity) {
  String templateFilePath = '${DslConstant.templateDir}/dart/package.temp';
  String targetFilePath =
      '${DslConstant.pluginPath}/${DslConstant.pluginName}/lib/${DslConstant.pluginName}.dart';

  List<String> methods = _makeMethods(entity);

  Map context = {
    'name': DslConstant.pluginName,
    'methods': methods.join('\n'),
  };
  DSLTooL.renderFile(templateFilePath, context, targetFilePath);
}

List<String> _makeMethods(UseCaseEntity entity) {
  List<String> methods = [];
  for (UseCaseClass cls in entity.classes) {
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
          '${DslConstant.templateDir}/dart/method.unit.temp', context);
      methods.add(methodStr);
    }
  }
  return methods;
}
