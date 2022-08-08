import 'dart:io';

import 'package:ab_dsl_interpreter/analyze/dsl_tool.dart';

import '../analyze/dsl_entity.dart';
import '../dsl_constant.dart';

class DSLToMarkDown {
  final UseCaseEntity entry;

  DSLToMarkDown({
    required this.entry,
  });

  String outDir = '${DslConstant.workspaceDir}/markdown';

  void generate() {
    Directory(outDir).createSync();

    Map context = {
      'pluginName': DslConstant.pluginName,
      'methodList': _makeMethodList().join('\n'),
    };

    String outPath = '$outDir/readme.md';
    DSLTooL.renderFile('${DslConstant.templateDir}/markdown/markdown.md.tmpl',
        context, outPath);

    // 将生成的文件拷贝到plugin目录
    String newPath =
        '${DslConstant.pluginPath}/${DslConstant.pluginName}/README.md';
    File(outPath).copy(newPath);
  }

  List<String> _makeMethodList() {
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

        if (method.comments.isEmpty) {
          continue;
        }

        Map methodUnitContext = _markdownMethodUnitContext(method);
        String methodStr = DSLTooL.renderUnit(
            '${DslConstant.templateDir}/markdown/markdown.method.tmpl',
            methodUnitContext);
        methods.add(methodStr);
      }
    }

    return methods;
  }

  Map _markdownMethodUnitContext(
    UseCaseMethod entity,
  ) {
    List<String> paramDescList = [];
    String methodDescribe = entity.comments.first.replaceAll('///', '');
    String argumentDes(String argument) {
      String des = "--";
      entity.comments.forEach((element) {
        if (element.contains(argument)) {
          des = element.replaceAll('///', '');
          des = des.replaceAll('[$argument]', '');
          return;
        }
      });
      return des;
    }

    //key:argName - value:argType
    List<String> paramList = <String>[];
    for (int i = 0; i < entity.arguments.length; i++) {
      ArgumentEntity argument = entity.arguments[i];
      paramList.add("${argument.name}:${argument.dartType}");
    }

    void _addParamDescList(String argName, String paramType, int index) {
      paramDescList.add("|" +
          "${argName}" +
          "|" +
          "$paramType" +
          "|" +
          argumentDes(argName) +
          "|");
    }

    for (int index = 0; index < paramList.length; index++) {
      List<String> paramStr = paramList[index].split(':');
      _addParamDescList(paramStr[0], paramStr[1], index);
    }

    String param = "";
    if (paramDescList.length > 0) {
      param = "| 参数名  | 参数类型  |  描述 |" +
          "\n" +
          "|---|---|---|" +
          "\n" +
          paramDescList.join("\n");
    }
    return {
      "methodDescribe": methodDescribe,
      "methodName": _makeMethodForMarkdown(entity),
      "paramDescribes": param,
    };
  }

  String _makeMethodForMarkdown(UseCaseMethod method) {
    String outPut = '';
    String argumentsString = "";
    method.arguments.forEach((element) {
      argumentsString += '${element.dartType} ${element.name},';
    });
    if (argumentsString.endsWith(',')) {
      argumentsString =
          argumentsString.substring(0, argumentsString.length - 1);
    }
    outPut += "${method.returnType} ${method.methodName}(${argumentsString})";
    return outPut;
  }
}
