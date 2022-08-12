import 'package:ab_dsl_interpreter/analyze/dsl_entity.dart';
import 'package:ab_dsl_interpreter/analyze/dsl_tool.dart';
import 'package:ab_dsl_interpreter/dsl_constant.dart';

void generate(UseCaseEntity entry) {
  List<String> methods = [];
  List<String> classes = [];
  List<String> enums = [];

  for (UseCaseClass cls in entry.classes) {
    // 可能存在其它Model类，抽象类才是需要解析的api,
    if (cls.superClass != 'PlatformInterface') {
      // 需要pigeon解析的类
      classes.add(cls.plainString);
      continue;
    }

    for (UseCaseMethod method in cls.methods) {
      if (method.methodName == 'instance') {
        continue;
      }
      String methodString = '@async\n';
      methodString +=
          '${method.syncReturnType} ${method.methodName}(${method.argsDefine});\n';
      methods.add(methodString);
    }
  }

  // 枚举
  for (EnumEntity ele in entry.enums) {
    enums.add(ele.plainString);
  }

  Map context = {
    'name': DslConstant.pascalPluginName,
    'methods': methods.join('\n'),
    'classes': classes.join('\n'),
    'enums': enums.join('\n'),
  };
  DSLTooL.renderFile('${DslConstant.templateDir}/dart/pigeon_api.temp', context,
      DslConstant.pigeonApiPath);
}
