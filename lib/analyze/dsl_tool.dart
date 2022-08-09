import 'dart:io';

import 'package:dart_casing/dart_casing.dart';

class DSLTooL {
  /// [context]需要替换的字段
  /// [targetFilePath]输出路径
  static renderFile(
      String templateFilePath, Map context, String targetFilePath) {
    String content = renderUnit(templateFilePath, context);
    File targetFile = File(targetFilePath);
    try {
      targetFile.writeAsStringSync(content);

      // 格式化
      if (targetFilePath.endsWith('.dart')) {
        ProcessResult ref = Process.runSync(
          'flutter',
          ['format', '$targetFilePath', '-l', '80'],
        );
        if ((ref.stdout as String).trim().split('\n').length > 1) {
          print(ref.stdout);
        }
      }
    } catch (e) {}
  }

  /// 模板文件根据内容替换
  /// [templateFilePath] 模板文件相对路径
  /// [context] 内容
  static String renderUnit(String templateFilePath, Map context) {
    String content = "";
    try {
      File templateFile = File(templateFilePath);
      content = templateFile.readAsStringSync();
    } catch (e) {
      print(e.toString());
    }
    context.forEach((key, value) {
      content = content.replaceAll("{{$key}}", value);
      content =
          content.replaceAll("{{$key.pascalCase()}}", Casing.pascalCase(value));
      content =
          content.replaceAll("{{$key.camelCase()}}", Casing.camelCase(value));
    });
    return content;
  }

  /// 创建全路径
  static void createFullPath(String pullPath) {
    try {
      List paths = pullPath.split('/');
      String nowPath = '';
      for (String path in paths) {
        nowPath += '$path/';
        var dir = Directory(nowPath);
        if (dir.existsSync() == false) {
          dir.createSync();
        }
      }
    } catch (ex) {
      print('createFullPath error: $ex');
    }
  }

  static String dateStr() {
    return '${DateTime.now().year.toString()}/${DateTime.now().month.toString()}/${DateTime.now().day.toString()}';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (length == 0) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  // 类型是否可选
  bool get isOptional {
    if (endsWith('?>') || endsWith('?')) {
      return true;
    }
    return false;
  }
}
