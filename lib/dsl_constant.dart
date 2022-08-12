import 'dart:convert';
import 'dart:io';

import 'package:dart_casing/dart_casing.dart';

import 'analyze/dsl_entity.dart';

class DslConstant {
  // 插件根目录
  static String pluginPath = '';

  // 插件名称
  static String pluginName = '';
  static String get pascalPluginName => Casing.pascalCase(pluginName);

  // pigeon api path
  static String get pigeonApiPath => '$platformDir/api.dart';

  // pigeon dart文件输出路径
  static String get pigeonDartOut =>
      '$platformDir/lib/src/method_channel_${DslConstant.pluginName}.dart';

  // pigeon java 文件输出路径
  static String get pigeonJavaOut =>
      '$pluginPath/${pluginName}_android/android/src/main/java/io/ambergroup/plugins/${pluginName}_android/pigeon.java';

  // generate src目录下的文件名
  static List<String> interfaceSrcFiles = [];

  // 工作区目录
  static String get workspaceDir => '$pluginPath/workspace';

  // platform_interface 目录
  static String get platformDir =>
      '$pluginPath/${pluginName}_platform_interface';

  // ios文件目录
  static String get iosScrDir => '$pluginPath/${pluginName}_ios/ios/Classes';

  // Android文件目录
  static String get androidSrcDic =>
      '$pluginPath/${pluginName}_android/android/src/main/java';

  // 模版目录
  static String get templateDir =>
      '$workspaceDir/ab_dsl_interpreter/lib/dsl_template';

  // json目录
  static String get dslJsonDir => '$workspaceDir/dsl_json';

  // 基础类型
  static const List<String> baseTypes = [
    'int',
    'double',
    'num',
    'String',
    'bool',
    'Map',
    'List',
    'dynamic',
    'void'
  ];

  static const Map<String, String> defaultValue = {
    'int': '0',
    'double': '0.0',
    'num': '0',
    'String': '\'\'',
    'bool': 'false',
    'Map': '{}',
    'List': '[]',
  };

  // 总数据
  static Map? _jsonData;
  static Map get jsonData {
    if (_jsonData == null) {
      _jsonData = _getJsonData('$workspaceDir/dsl_json');
      _getEnumAndCallbacks();
    }
    return _jsonData!;
  }

  // 所有原生类的转换信息
  static Map<String, Set> appendIosImports = Map();

  static Set<String> allIOSAbstractClass = Set();

  // 所有的抽象类名称
  static Set<String> allAbstractClass = Set();

  // 所有抽象类
  static Set<UseCaseClass> allAbstractObjectClass = Set();

  // 所有对象
  static Set<UseCaseClass> allObjectClass = Set();
  // 需要重写的类名
  static Map<String, String> iosRewriteNameMap = {};
  static Map<String, String> androidRewriteNameMap = {};

  // 所有枚举
  static List<EnumEntity> get allEnums => _allEnums;
  static List<EnumEntity> _allEnums = [];
  // 所有常量类型
  static List<EnumEntity> _allConstants = [];
  static List<EnumEntity> get allConstants => _allConstants;

  // 所有回调
  static List<UseCaseMethod> get allCallbacks => _allCallbacks;
  static List<UseCaseMethod> _allCallbacks = [];

  // 所有自定义的listener
  static List<UseCaseClass> get allListeners => _allListeners;
  static List<UseCaseClass> _allListeners = [];
  // static List<AndroidCallback> listAndroidCallbacks = [];

  // 所有枚举数据名称
  static List<String> _enumNameList = [];
  static List<String> get enumNameList {
    _enumNameList = allEnums.map((e) => e.name).toList();
    return _enumNameList;
  }

  // 所有头文件
  static List<String> allFilePaths = [];

  static List<String> _backNameList = [];

  static List<String> _allFileNames = [];
  static List<String> get allFileNames {
    _allFileNames = allFilePaths.map((e) {
      return e.split('/').last.split('.json').first;
    }).toList();
    return _allFileNames;
  }

  // 所有回调名称
  static List<String> get backNameList {
    _backNameList = allCallbacks.map((e) => e.methodName).toList();
    return _backNameList;
  }

  static Map _getJsonData(String filePath) {
    Directory dslDir = Directory(filePath);

    List<FileSystemEntity> dslDirList =
        dslDir.listSync(recursive: false, followLinks: false);
    Map<String, dynamic> dataSource = {};
    dslDirList.forEach((element) {
      Map useCaseData = _readAllJsonDataFromPath(filePath, "api");
      dataSource["api"] = useCaseData;
    });
    return dataSource;
  }

  static Map _readAllJsonDataFromPath(String path, String type) {
    var dslDir = Directory(path);
    if (!dslDir.existsSync()) return {};
    List<FileSystemEntity> dslDirList =
        dslDir.listSync(recursive: false, followLinks: false);
    Map<String, dynamic> dataSource = {};
    dslDirList.forEach((element) {
      String jsonPath = element.path;
      String fileName = element.path.split("/").last;
      fileName = fileName.split(".").first;
      if (fileName.isNotEmpty) {
        dynamic jsonData = _readJsonFromFile(jsonPath);
        allFilePaths.add(jsonPath);
        if (type == "api") {
          dataSource[fileName] = UseCaseEntity.fromJson(jsonData);
        }
      }
    });
    return dataSource;
  }

  static Map _readJsonFromFile(String path) {
    File file = File(path);
    String jsonStr = file.readAsStringSync();
    return jsonDecode(jsonStr);
  }

  static void _getEnumAndCallbacks() {
    _allEnums = [];
    _allConstants = [];
    _allCallbacks = [];

    _jsonData!.forEach((key, value) {
      Map useCaseMap = value;
      useCaseMap.forEach((key, value) {
        if (value is UseCaseEntity) {
          _allCallbacks.addAll(value.callbacks);
        }
      });
    });
  }
}
