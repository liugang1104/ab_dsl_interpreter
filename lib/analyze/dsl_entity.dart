import '../dsl_constant.dart';

mixin RewriteClass {
  String iOSRewriteName = '';
  String androidRewriteName = '';

  void rewriteByJson(Map<String, dynamic> json) {
    Map annotation = json['annotation'];
    iOSRewriteName = annotation['iOSRewriteName'];
    androidRewriteName = annotation['androidRewriteName'];
  }
}

mixin ImportEntity {
  List<String> _ios_import = [];
  List<String> _android_import = [];
  List<String> _dart_import = [];

  List<String> get android_import => _android_import;

  List<String> get dart_import => _dart_import;
}

class EnumEntity with RewriteClass {
  String name = '';

  EnumEntity.fromJson(Map<String, dynamic> json) {
    rewriteByJson(json);
    name = json['name'];
  }
}

class EnumListEntity {
  List<EnumEntity> enums = [];

  EnumListEntity.fromJson(Map<String, dynamic> json) {
    enums = [];
    if (json["enum"] != null) {
      for (var item in json["enum"]) {
        enums.add(EnumEntity.fromJson(item));
      }
    }
  }
}

class PropertyEntity {
  final String name;
  final String serializedName;
  final String type;
  final bool isStatic;
  final bool isFinal;
  final String deprecated;
  final dynamic value;

  String get dartType {
    if (type == 'LongLong') {
      return 'int';
    }
    return type;
  }

  bool get isNativeReturnType {
    return dartType.endsWith("Native");
  }

  bool get isNativeListReturnType {
    return dartType.startsWith("List<") &&
        dartType.substring(4).endsWith("Native>");
  }

  PropertyEntity({
    this.type = '',
    this.name = '',
    this.serializedName = '',
    this.isStatic = false,
    this.isFinal = false,
    this.deprecated = '',
    this.value,
  });

  factory PropertyEntity.fromJson(Map json) {
    json ??= {};
    Map annotation = json['annotation'] ?? {};
    return PropertyEntity(
      type: json['type'] ?? '',
      name: json['name'] ?? "",
      deprecated: json['deprecated'] ?? "",
      isStatic: json['isStatic'] ?? false,
      isFinal: json['isFinal'] ?? false,
      value: json['value'],
      serializedName: json['serializedName'] ?? '',
    );
  }
}

class ModelEntity with RewriteClass, ImportEntity {
  List<String> ios_import = [];
  List<String> android_import = [];
  List<String> dart_import = [];
  Map<String, PropertyEntity> properties = {};
  String className = '';

  bool isSerializable = false;
  bool isParcelable = false;
  bool isCloneable = false;
  bool isKeep = false;
  bool isStatic = false;

  ModelEntity.fromJson(Map<String, dynamic> json) {
    rewriteByJson(json);
    var _properties = json['properties'];
    if (_properties != null && _properties is Map) {
      properties = _properties.map<String, PropertyEntity>((key, value) {
        return MapEntry(key, PropertyEntity.fromJson(value));
      });
    }
    className = json['className'];
    isStatic = json['isStatic'] ?? false;
    isSerializable = json['isSerializable'] ?? false;
    isParcelable = json['isParcelable'] ?? false;
    isCloneable = json['isCloneable'] ?? false;
    isKeep = json['isKeep'] ?? false;
  }
}

class ModelListEntity {
  List<String> ios_import = [];
  List<String> android_import = [];
  List<String> dart_import = [];
  List<ModelEntity> classes = [];

  ModelListEntity.fromJson(Map<String, dynamic> json) {
    if (json['ios_import'] != null) {
      for (var item in json['ios_import']) {
        ios_import.add(item);
      }
    }
    if (json['android_import'] != null) {
      for (var item in json['android_import']) {
        android_import.add(item);
      }
    }
    if (json['dart_import'] != null) {
      for (var item in json['dart_import']) {
        dart_import.add(item);
      }
    }
    if (json['classes'] != null) {
      for (var item in json['classes']) {
        classes.add(ModelEntity.fromJson(item));
      }
    }
  }
}

class UseCaseClass with RewriteClass {
  String className;
  final List<UseCaseMethod> methods;
  final bool isStatic;
  final bool isSingleton;
  final bool isAbstract;
  final String deprecated;
  final String superClass;
  final List<PropertyEntity> memberVariables;
  String androidPckName;

  UseCaseClass({
    this.className = '',
    this.methods = const [],
    this.isStatic = false,
    this.isAbstract = false,
    this.deprecated = '',
    this.isSingleton = false,
    this.memberVariables = const [],
    this.superClass = '',
    this.androidPckName = '',
  });

  factory UseCaseClass.fromMap(Map map) {
    UseCaseClass useCaseClass = UseCaseClass(
      className: map['className'],
      methods: ((map['methods'] ?? []) as List)
          .map((e) => UseCaseMethod.fromMap(e))
          .toList(),
      isStatic: map['isStatic'] ?? false,
      isSingleton: map['isSingleton'] ?? false,
      isAbstract: map['isAbstract'] ?? false,
      deprecated: map['deprecated'] ?? "",
      superClass: map['superClass'] ?? "",
      memberVariables: ((map['memberVariables'] ?? []) as List)
          .map((e) => PropertyEntity.fromJson(e))
          .toList(),
    );
    // useCaseClass.rewriteByJson(map.cast<String, dynamic>());
    return useCaseClass;
  }
}

class UseCaseMethod {
  //下面两个用于Android的method中的callback收集
  AndroidCallback? callback;
  String callbackMethodName;

  final String platform;
  final String methodName;
  final String returnType;
  final List<ArgumentEntity> arguments;
  final String nullFlag;
  final bool isStatic;
  final String deprecated;
  // final CallbackParam? callbackParam;

  UseCaseMethod({
    this.callbackMethodName = '',
    this.platform = '',
    this.methodName = '',
    this.returnType = '',
    this.arguments = const [],
    this.nullFlag = '',
    this.isStatic = false,
    this.deprecated = '',
  });

  factory UseCaseMethod.fromMap(Map map) {
    return UseCaseMethod(
      platform: map['platform'] ?? "",
      methodName: map['methodName'] ?? "",
      returnType: map['returnType'] ?? "",
      nullFlag: map['nullFlag'] ?? "",
      isStatic: map['isStatic'] ?? false,
      arguments: ((map['arguments'] ?? []) as List)
          .map((e) => ArgumentEntity.fromJson(e))
          .toList(),
      deprecated: map['deprecated'] ?? "",
    );
  }

  bool get isVoidReturnType => returnType == 'Future<void>';

  // channel 返回值类型，obj类型转为map
  String get castType {
    if (baseTypes.contains(originReturnType) ||
        originReturnType.startsWith('Map<') ||
        originReturnType.startsWith('List<')) {
      return originReturnType;
    }
    return 'Map<String, dynamic>';
  }

  // 不带Future的返回值类型
  String get originReturnType {
    if (returnType.startsWith('Future')) {
      return returnType.substring(7, returnType.length - 1);
    }
    return returnType;
  }

  // 方法参数定义: String arg1, int arg2
  String get argsDefine {
    String str = "";
    for (ArgumentEntity element in arguments) {
      str += '${element.dartType} ${element.name}, ';
    }
    if (str.endsWith(', ')) {
      str = str.substring(0, str.length - 2);
    }
    return str;
  }

  // 方法入参数: arg1, arg2, arg3
  String get argsInput {
    String str = "";
    for (ArgumentEntity element in arguments) {
      str += '${element.name}, ';
    }
    if (str.endsWith(', ')) {
      str = str.substring(0, str.length - 2);
    }
    return str;
  }

  static final String voidReturn = 'Future<dynamic>';

  String get realReturnType {
    if (returnType == null ||
        returnType.isEmpty ||
        returnType == '' ||
        returnType == 'void') {
      return voidReturn;
    } else {
      return 'Future<$returnType>';
    }
  }

  String get callbackReturnType {
    String returnType = "";
    //返回success回调里的参数
    arguments.forEach((element) {
      if (element.name == 'success' && element.callback!.arguments.isNotEmpty) {
        if (element.callback!.arguments.length > 1) {
          //多个参数聚合到map里
          returnType = 'Map';
        } else {
          returnType = element.callback!.arguments[0].type;
          if (returnType == 'LongLong') {
            returnType = 'int';
          }
        }
      }
    });
    return returnType;
  }

  String get callbackReturnKey {
    List<ArgumentEntity?>? args = arguments!
        .singleWhere((element) => element.name == 'success')
        ?.callback
        ?.arguments;
    return args != null && args.length == 1 ? args[0]!.name : '';
  }

  bool get isSuccessCallbackMultiArgs {
    ArgumentEntity? arg = arguments.singleWhere(
      (element) => element.name == 'success',
    );
    if (arg != null) {
      return arg.callback!.arguments.length > 1;
    }
    return false;
  }

  bool get isNativeReturnType {
    return returnType.endsWith("Native") ||
        callbackReturnType.endsWith("Native");
  }

  bool get isNativeListReturnType {
    return returnType.startsWith("List<") &&
            returnType.substring(4).endsWith("Native>") ||
        (callbackReturnType.startsWith("List<") &&
            callbackReturnType.substring(4).endsWith("Native>"));
  }
}

class UseCaseEntity with ImportEntity {
  List<UseCaseMethod> callbacks = [];
  List<UseCaseClass> classes = [];
  List<UseCaseMethod> typedefCallbacks = [];

  UseCaseEntity.fromJson(Map<String, dynamic> json) {
    if (json['ios_import'] != null) {
      for (var item in json['ios_import']) {
        _ios_import.add(item);
      }
    }
    if (json['android_import'] != null) {
      for (var item in json['android_import']) {
        _android_import.add(item);
      }
    }
    if (json['dart_import'] != null) {
      for (var item in json['dart_import']) {
        if (!(item as String).endsWith("Listener.dart';")) {
          _dart_import.add(item);
        }
      }
    }
    classes = ((json['classes'] ?? []) as List)
        .map((e) => UseCaseClass.fromMap(e))
        .toList();
    if (json['callbacks'] != null) {
      for (var item in json['callbacks']) {
        callbacks.add(UseCaseMethod.fromMap(item));
      }
    }
    if (json['typedefCallbacks'] != null) {
      for (var item in json['typedefCallbacks']) {
        typedefCallbacks.add(UseCaseMethod.fromMap(item));
      }
    }
  }
}

class ArgumentEntity {
  String type = '';
  String name = '';
  String nullFlag = '';
  String argType = '';
  UseCaseMethod? callback;

  String get dartType {
    if (type == 'LongLong') {
      return 'int';
    }
    return type;
  }

  bool get isNativeType {
    return dartType.endsWith("Native");
  }

  bool get isNativeListType {
    return dartType.startsWith("List<") &&
        dartType.substring(4).endsWith("Native>");
  }

  ArgumentEntity.fromJson(Map<String, dynamic> json) {
    type = json["type"];
    name = json["name"];
    nullFlag = json["nullFlag"] ?? "";
    argType = json["argType"] ?? "";
    if (json['callbackMap'] != null) {
      callback = UseCaseMethod.fromMap(json['callbackMap'] ?? {});
    }
  }
}

class Configure {
  final String name;
  final String source;
  final String version;
  final String description;
  final String android_result_callback_name;
  final String android_model_suffix;
  final String ios_model_suffix;
  // final ConfigureInfo androidManagerConfigure;
  // AndroidConfigureInfo androidModuleConfigure;
  // ConfigureInfo iosConfigure;
  // ConfigureInfo flutterConfigure;
  // ConfigureInfo iosModuleConfigure;
  final String iosNameSpace;
  final String androidNameSpace;
  final String ios_string_property;

  Configure({
    this.name = '',
    this.source = '',
    this.version = '',
    this.description = '',
    this.android_result_callback_name = '',
    this.android_model_suffix = '',
    this.ios_model_suffix = '',
    this.iosNameSpace = '',
    this.androidNameSpace = '',
    this.ios_string_property = '',
  });

  Configure.fromJson(Map json)
      : name = json["name"] ?? "".replaceAll(" ", ""),
        source = json["source"] ?? "",
        version = json["version"] ?? "",
        ios_string_property = json["ios_string_property"] ?? "strong",
        description = json["description"] ?? "",
        android_result_callback_name =
            json["android_result_callback_name"] ?? "",
        android_model_suffix = json["android_model_suffix"] ?? "",
        ios_model_suffix = json["ios_model_suffix"] ?? "",
        iosNameSpace = json['ios_name_space'] ?? '',
        androidNameSpace = json['android_name_space'] ?? '';
  // androidManagerConfigure =
  //     ConfigureInfo.fromJson(json["android_configure_manager"] ?? {}),
  // androidModuleConfigure = AndroidConfigureInfo.fromJson(
  //     json["android_configure_usecase_module"] ?? {}),
  // iosConfigure = ConfigureInfo.fromJson(json["ios_configure"] ?? {}),
  // flutterConfigure =
  //     ConfigureInfo.fromJson(json["flutter_configure"] ?? {}),
  // android_generic_list_to_arraylist =
  //     json["android_generic_list_to_arraylist"] ?? true,
  // iosModuleConfigure = ConfigureInfo.fromJson(
  //     json["ios_configure_ty_ka_usecase_module"] ?? {}
  // );
}

class ConfigureInfo {
  final String path;
  final GitInfo git;
  final String name;
  final String sdk_header;

  ConfigureInfo.fromJson(Map json)
      : git = GitInfo.fromJson(json["git"] ?? {}),
        path = json["path"] ?? "",
        sdk_header = json["sdk_import_header"] ?? "",
        name = json["name"];
}

class AndroidConfigureInfo {
  final String path;
  final GitInfo git;
  final String name;
  final String sdk_header;
  final bool kotlin_code;

  AndroidConfigureInfo.fromJson(Map json)
      : git = GitInfo.fromJson(json["git"] ?? {}),
        path = json["path"] ?? "",
        sdk_header = json["sdk_import_header"] ?? "",
        kotlin_code = json["kotlin_code"] ?? false,
        name = json["name"];
}

class GitInfo {
  final String url;
  final String branch;

  GitInfo.fromJson(Map json)
      : url = json['url'] ?? "",
        branch = json['branch'] ?? "";
}

class AndroidCallback {
  static final TYPE_CALLBACK = 1;
  static final TYPE_RESULT_CALLBACK = 2;
  static final TYPE_SUCCESS_CALLBACK = 3;
  static final TYPE_SUCCESS_RESULT_CALLBACK = 4;
  String callbackName;
  int startIndex = -1;
  List<UseCaseMethod> callbackMethods = [];
  bool isGeneralCallback = false; //是否为通用的callback类型，默认false
  String genericDartType = ""; //范型类型

  int get generalCallbackType {
    if (callbackName.startsWith('ITYKACallback')) {
      return TYPE_CALLBACK;
    } else if (callbackName.startsWith('ITYKAResultCallback')) {
      return TYPE_RESULT_CALLBACK;
    } else if (callbackName.startsWith('ITYKASuccessCallback')) {
      return TYPE_SUCCESS_CALLBACK;
    } else if (callbackName.startsWith('ITYKASuccessResultCallback')) {
      return TYPE_SUCCESS_RESULT_CALLBACK;
    } else {
      return -1;
    }
  }

  String get generalCallbackPck {
    if (callbackName.startsWith('ITYKACallback')) {
      return 'com.tuya.smart.kausecasemanager.callback.ITYKACallback';
    } else if (callbackName.startsWith('ITYKAResultCallback')) {
      return 'com.tuya.smart.kausecasemanager.callback.ITYKAResultCallback';
    } else if (callbackName.startsWith('ITYKASuccessCallback')) {
      return 'com.tuya.smart.kausecasemanager.callback.ITYKASuccessCallback';
    } else if (callbackName.startsWith('ITYKASuccessResultCallback')) {
      return 'com.tuya.smart.kausecasemanager.callback.ITYKASuccessResultCallback';
    } else {
      return '';
    }
  }

  AndroidCallback({this.callbackName = '', this.startIndex = -1});
}
