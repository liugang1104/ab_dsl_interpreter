import 'dart:convert';
import 'dart:io';

import 'analyze/dsl_entity.dart';

const List<String> baseTypes = [
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

const Map<String, String> defaultValue = {
  'int': '0',
  'double': '0.0',
  'num': '0',
  'String': '\'\'',
  'bool': 'false',
  'Map': '{}',
  'List': '[]',
};

class DslConstant {
  // 插件根目录
  static String pluginPath = '';

  // 插件名称
  static String pluginName = '';

  // generate src目录下的文件名
  static List<String> interfaceSrcFiles = [];

  // 工作区目录
  static String get workspaceDir => '$pluginPath/workspace';

  // 模版目录
  static String get templateDir =>
      '$workspaceDir/ab_dsl_interpreter/lib/dsl_template';

  // json目录
  static String get dslJsonDir => '$workspaceDir/dsl_json';

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

  // 所有模型
  static List<ModelEntity> allModels = [];
  static List<String> _allModelClassNames = [];
  static List<String> get allModelClassNames {
    if (_allModelClassNames.isEmpty) {
      _allModelClassNames = allModels.map<String>((e) => e.className).toList();
    }
    return _allModelClassNames;
  }

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
  static List<AndroidCallback> listAndroidCallbacks = [];

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
        if (type == "model") {
          dataSource[fileName] = ModelListEntity.fromJson(jsonData);
        } else if (type == "api") {
          dataSource[fileName] = UseCaseEntity.fromJson(jsonData);
        } else if (type == "enum" || type == "constants") {
          dataSource[fileName] = EnumListEntity.fromJson(jsonData);
        } else if (type == "callback") {
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
    var rewriteFunc = (RewriteClass element, String key) {
      if (element.iOSRewriteName.isNotEmpty == true) {
        iosRewriteNameMap[key] = element.iOSRewriteName;
      }
      if (element.androidRewriteName.isNotEmpty == true) {
        androidRewriteNameMap[key] = element.androidRewriteName;
      }
    };

    _jsonData!.forEach((key, value) {
      Map useCaseMap = value;

      var rewriteUseCaseMap = (UseCaseClass element) {
        rewriteFunc(element, element.className);
        allObjectClass.add(element);
        if (element.isAbstract) {
          allAbstractObjectClass.add(element);
          allIOSAbstractClass.add(element.className);
          allAbstractClass.add(element.className);
        }
      };

      useCaseMap.forEach((key, value) {
        if (value is UseCaseEntity) {
          _allCallbacks.addAll(value.callbacks);
          value.classes.forEach((element) => rewriteUseCaseMap(element));
        }
      });
    });
  }
}
