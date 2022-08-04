library ab_dsl_interpreter;

import 'package:ab_dsl_interpreter/dsl_constant.dart';
import 'package:ab_dsl_interpreter/generate/dsl_to_entrance.dart';
import 'package:ab_dsl_interpreter/generate/dsl_to_ios.dart';

import 'analyze/dsl_ast.dart' as dsl_ast;
import 'generate/dsl_to_interface.dart';

main(List<String> args) {
  String rootPath = args[0];
  String pluginName = args[1];

  // String rootPath = '/Users/mark.liu/MyFiles/work/share/my_plugin';
  // String pluginName = 'my_plugin';

  DslConstant.pluginPath = rootPath;
  DslConstant.pluginName = pluginName;

  // 解析dart文件，生成json
  dsl_ast.generateJsonFile();

  // 生成对应平台的文件
  Map jsonData = DslConstant.jsonData;
  jsonData.forEach((final key, final value) {
    value.forEach((key, value) {
      if (key.toString().contains('platform_interface')) {
        DSLToInterface(entry: value).generate();
        DSLToEntrance(entry: value).generate();
        DSLToIos(entry: value).generate();
      }
    });
  });
}
