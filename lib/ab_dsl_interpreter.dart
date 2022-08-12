import 'dart:io';

import 'package:ab_dsl_interpreter/dsl_constant.dart';
import 'package:ab_dsl_interpreter/generate/dsl_to_markdown.dart';
import 'package:path/path.dart' as path;

import 'analyze/dsl_ast.dart' as DSL_AST;
import 'generate/dsl_to_api.dart' as DSLToApi;
import 'generate/dsl_to_dart.dart' as DSLToDart;
import 'generate/dsl_to_ios.dart' as DSLToIos;

main(List<String> args) {
  String rootPath = '/Users/mark.liu/share/test/sk_device';

  // String rootPath = args[0];
  String pluginName = path.basename(rootPath);

  DslConstant.pluginPath = rootPath;
  DslConstant.pluginName = pluginName;

  // 解析dart文件，生成json
  DSL_AST.generateJsonFile();

  // 生成对应平台的文件
  Map jsonData = DslConstant.jsonData;
  jsonData.forEach((final key, final value) {
    value.forEach((key, value) {
      if (key.toString().contains('platform_interface')) {
        DSLToDart.generate(value);
        DSLToIos.generate(value);
        DSLToApi.generate(value);
        DSLToMarkDown(entry: value).generate();
      }
    });
  });

  _generatePigeonCode();
}

//调用pigeon,生成三端通信代码
void _generatePigeonCode() {
  Map args = {
    'input': DslConstant.pigeonApiPath,
    'dart_out': DslConstant.pigeonDartOut,
    'objc_header_out':
        '${DslConstant.iosScrDir}/${DslConstant.pascalPluginName}Pigeon.h',
    'objc_source_out':
        '${DslConstant.iosScrDir}/${DslConstant.pascalPluginName}Pigeon.m',
    'java_out': DslConstant.pigeonJavaOut,
  };
  String options = 'pub run pigeon';
  args.forEach((key, value) {
    options += ' --$key $value';
  });
  ProcessResult ref = Process.runSync('flutter', options.split(' '));
  if ((ref.stderr as String).trim().split('\n').length > 1) {
    print(ref.stderr);
  }

  // 将pigeon生成的dart继承自Platform
  String content = File(DslConstant.pigeonDartOut).readAsStringSync();
  content = content.replaceAll('class ${DslConstant.pascalPluginName}Api {',
      'class ${DslConstant.pascalPluginName}Api extends ${DslConstant.pascalPluginName}Platform {');

  // 插入import
  String fromStr = 'package:flutter/services.dart\';\n';
  String toStr =
      '${fromStr}import \'${DslConstant.pluginName}_platform_interface.dart\';\n';
  content = content.replaceAll(fromStr, toStr);
  File(DslConstant.pigeonDartOut).writeAsStringSync(content);
}
