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

  // dsl工作区目录名称
  static const String workspace = 'workspace';
  static const String dslJsonTempPath = "dsl_json";

  static const String dslSourceProjectPath = "tuya_usecase_api_dsl";

  static const String INTERFACE = "Interface";
  static const String USECASE = "UseCase";
  static const String PROXY = "Proxy";
  static const String RCTMANAGER = "Manager";
  static const String TYRCT = "TYRCT";

  static const String CALLBACK = "callback";
  static const String API = "api";
  static const String IMPL = "impl";
  static const String ENUM = "enum";
  static const String MODEL = "model";
  static const String NATIVE = "native";

  static String dslBranch = "DSL";

  //yaml配置信息
  static Configure configure = Configure();

  // 总数据
  static Map? _jsonData;
  static Map get jsonData {
    if (_jsonData == null) {
      _jsonData = _getJsonData('$workspaceDir/dsl_json');
      _getEnumAndCallbacks();
    }
    // androidExtra();
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
    if (_allModelClassNames == null || _allModelClassNames.isEmpty) {
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
    if (_enumNameList == null) {
      _enumNameList = allEnums?.map((e) => e.name)?.toList() ?? [];
    }
    return _enumNameList;
  }

  // 所有头文件
  static List<String> allFilePaths = [];

  static List<String> _backNameList = [];

  static Map<String, String> _iosReplaceFileNameMap = {};
  static Map<String, String> get iosReplaceFileNameMap {
    if (_iosReplaceFileNameMap == null) {
      _iosReplaceFileNameMap = {};
      allFileNames.forEach((element) {
        if (iosRewriteNameMap.containsKey(element)) {
          var key = '#import "$element.h"';
          var value = '#import "${iosRewriteNameMap[element]}.h"';
          _iosReplaceFileNameMap[key] = value;
        }
      });
    }
    return _iosReplaceFileNameMap;
  }

  static Map<String, String> _iosSDKFileNameMap = {};
  static Map<String, String> get iosSDKFileNameMap {
    if (_iosSDKFileNameMap == null) {
      _iosSDKFileNameMap = {};
      allFileNames.forEach((element) {
        var key = '#import "$element.h"';
        // if (DslConstant.configure.iosModuleConfigure.sdk_header.length != 0) {
        //   if (iosRewriteNameMap.containsKey(element)) {
        //     var value =
        //         '#import <${DslConstant.configure.iosModuleConfigure.sdk_header}/${iosRewriteNameMap[element]}.h>';
        //     _iosSDKFileNameMap[key] = value;
        //   } else {
        //     var value =
        //         '#import <${DslConstant.configure.iosModuleConfigure.sdk_header}/$element.h>';
        //     _iosSDKFileNameMap[key] = value;
        //   }
        // } else {
        //   if (iosRewriteNameMap.containsKey(element)) {
        //     var value = '#import "${iosRewriteNameMap[element]}.h"';
        //     _iosSDKFileNameMap[key] = value;
        //   }
        // }
      });
    }
    return _iosSDKFileNameMap;
  }

  static List<String> _allFileNames = [];
  static List<String> get allFileNames {
    if (_allFileNames == null) {
      _allFileNames = allFilePaths.map((e) {
        if (e is String) {
          return e.split('/').last.split('.json').first;
        }
        return '';
      }).toList();
    }
    return _allFileNames;
  }

  // 所有回调名称
  static List<String> get backNameList {
    if (_backNameList == null) {
      _backNameList = allCallbacks?.map((e) => e.methodName)?.toList() ?? [];
    }
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
        } else if (type == "native") {
          findNativeObject(jsonData);
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
      if (element.iOSRewriteName?.isNotEmpty == true) {
        iosRewriteNameMap[key] = element.iOSRewriteName;
      }
      if (element.androidRewriteName?.isNotEmpty == true) {
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

  //把Android的方法中的回调收集放到一个callabck中
  static void androidExtra() {
    _jsonData!.forEach((key, value) {
      Map useCaseMap = value["api"];
      useCaseMap.forEach((key, value) {
        if (value is UseCaseEntity) {
          //1、遍历所有uc class
          value.classes.forEach((usecaseClass) {
            //2、遍历uc里的所有方法
            usecaseClass.methods.forEach((usecaseMethod) {
              List<UseCaseMethod> listCallbackMethods = [];
              int index = -1;
              //3、遍历方法参数
              for (int i = 0; i < usecaseMethod.arguments.length; i++) {
                ArgumentEntity argument = usecaseMethod.arguments[i];
                _allCallbacks.forEach((callbackMethod) {
                  if (argument.type == callbackMethod.methodName) {
                    if (index < 0) {
                      index = i;
                    }
                    //Android methodName处理成Android所需要的，类似onSuccess这种此处就是success
                    callbackMethod.callbackMethodName = argument.name;
                    listCallbackMethods.add(callbackMethod);
                  }
                });
              }

              //为避免影响到iOS端生成的代码，只在Android端代码生成流程中做处理，不在json解析源头做处理
              //若后期需要两端都统一优化，则可以在dart转json流程中做处理
              // if (listCallbackMethods.length > 0) {
              //   AndroidCallback androidCallback = new AndroidCallback();
              //   androidCallback.startIndex = index;
              //   UseCaseMethod successMethod = listCallbackMethods.firstWhere(
              //       (element) => element.callbackMethodName == "success",
              //       orElse: () => null);
              //   UseCaseMethod failureMethod = listCallbackMethods.firstWhere(
              //       (element) => element.callbackMethodName == "failure",
              //       orElse: () => null);
              //   if (successMethod != null &&
              //       listCallbackMethods.length <= 2 &&
              //       successMethod.arguments.length < 2) {
              //     //范型类型
              //     String funcArgType = successMethod.arguments.length > 0
              //         ? successMethod.arguments[0].type
              //         : '';
              //     androidCallback.genericDartType = funcArgType;
              //     String genericsType = AndroidTools.dartToAndroidGenericType(
              //         funcArgType, new Set());
              //     if (genericsType.endsWith("Model")) {
              //       genericsType =
              //           DSLTOOL.androidAppendModelSuffix(genericsType);
              //     }
              //
              //     //单方法回调
              //     if (listCallbackMethods.length == 1) {
              //       //如果范型类型为空，则使用无范型参数的回调ITYKASuccessCallback
              //       if (genericsType.isNotEmpty) {
              //         androidCallback.callbackName =
              //             "ITYKASuccessResultCallback<${genericsType}>";
              //       } else {
              //         androidCallback.callbackName = "ITYKASuccessCallback";
              //       }
              //       androidCallback.callbackMethods = listCallbackMethods;
              //       androidCallback.isGeneralCallback = true;
              //     } else if (listCallbackMethods.length == 2 &&
              //         failureMethod != null) {
              //       //success 、failure回调
              //       //如果范型类型为空，则使用无范型参数的回调ITYKACallback
              //       if (genericsType.isNotEmpty) {
              //         androidCallback.callbackName =
              //             "ITYKAResultCallback<${genericsType}>";
              //       } else {
              //         androidCallback.callbackName = "ITYKACallback";
              //       }
              //       androidCallback.callbackMethods = listCallbackMethods;
              //       androidCallback.isGeneralCallback = true;
              //     }
              //   } else {
              //     androidCallback.startIndex = index;
              //     androidCallback.callbackName = "I" +
              //         AndroidTools.upperFirstLetter(usecaseMethod.methodName) +
              //         "Callback";
              //     androidCallback.callbackMethods = listCallbackMethods;
              //   }
              //   usecaseMethod.callback = androidCallback;
              // }
            });
          });
        }
      });
    });
  }

  static void findNativeObject(Map map) {
    if (map == null) {
      return;
    }
    List classMapList = map['classes'];
    classMapList.forEach((map) {
      String className = map['className'];
    });

    Map callbackMap = map['callbackMap'];
    callbackMap.forEach((key, value) {
      allCallbacks.add(UseCaseMethod.fromMap(value));
    });
  }

  static bool isCallBack(String dirs) {
    if (dirs != null && dirs.contains("/$CALLBACK/")) {
      return true;
    }
    return false;
  }

  static bool isApi(String dirs) {
    if (dirs != null && dirs.contains("/$API/")) {
      return true;
    }
    return false;
  }

  static bool isImpl(String dirs) {
    if (dirs != null && dirs.contains("/$IMPL/")) {
      return true;
    }
    return false;
  }

  static bool isEnum(String dirs) {
    if (dirs != null && dirs.contains("/$ENUM/")) {
      return true;
    }
    return false;
  }

  static bool isModel(String dirs) {
    if (dirs != null && dirs.contains("/$MODEL/")) {
      return true;
    }
    return false;
  }

  static bool isNative(String dirs) {
    if (dirs != null && dirs.contains("/$NATIVE/")) {
      return true;
    }
    return false;
  }
}
