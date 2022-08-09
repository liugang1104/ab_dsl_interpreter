library ab_dsl_interpreter;

import 'package:ab_dsl_interpreter/dsl_constant.dart';
import 'package:ab_dsl_interpreter/generate/dsl_to_entrance.dart';
import 'package:ab_dsl_interpreter/generate/dsl_to_ios.dart';
import 'package:ab_dsl_interpreter/generate/dsl_to_markdown.dart';
import 'package:path/path.dart' as path;

import 'analyze/dsl_ast.dart' as dsl_ast;
import 'generate/dsl_to_interface.dart';

main(List<String> args) {
  // String rootPath = '/Users/mark.liu/pub_self/sk_device';

  String rootPath = args[0];
  String pluginName = path.basename(rootPath);

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
        DSLToMarkDown(entry: value).generate();
        print("🎈🎈🎈 All done! 🎈🎈🎈");
      }
    });
  });
}
