mixin ImportEntity {
  List<String> _ios_import = [];
  List<String> _android_import = [];
  List<String> _dart_import = [];

  List<String> get android_import => _android_import;

  List<String> get dart_import => _dart_import;
}

class EnumEntity {
  String name = '';

  EnumEntity.fromJson(Map<String, dynamic> json) {
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
  final List<String> comments;

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
    this.comments = const [],
  });

  factory PropertyEntity.fromJson(Map json) {
    return PropertyEntity(
        type: json['type'] ?? '',
        name: json['name'] ?? '',
        deprecated: json['deprecated'] ?? "",
        isStatic: json['isStatic'] ?? false,
        isFinal: json['isFinal'] ?? false,
        value: json['value'],
        serializedName: json['serializedName'] ?? '',
        comments: json['comments'] ?? []);
  }
}

class ModelEntity with ImportEntity {
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

class UseCaseClass {
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
    return useCaseClass;
  }
}

class UseCaseMethod {
  //下面两个用于Android的method中的callback收集
  // AndroidCallback? callback;
  String callbackMethodName;

  final String platform;
  final String methodName;
  final String returnType;
  final List<String> comments;
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
    this.comments = const [],
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
        nullFlag: map['nullFlag'] ?? '',
        isStatic: map['isStatic'] ?? false,
        arguments: ((map['arguments'] ?? []) as List)
            .map((e) => ArgumentEntity.fromJson(e))
            .toList(),
        deprecated: map['deprecated'] ?? "",
        comments: map['comments'] ?? []);
  }

  bool get isVoidReturnType => returnType == 'Future<void>';

  // 不带Future 和 ？的返回值类型
  String _originReturnType = '';
  String get originReturnType {
    if (_originReturnType.isNotEmpty) {
      return _originReturnType;
    }
    _originReturnType = returnType;
    if (_originReturnType.startsWith('Future')) {
      _originReturnType =
          _originReturnType.substring(7, _originReturnType.length - 1);
    }
    if (_originReturnType.endsWith('?')) {
      _originReturnType =
          _originReturnType.substring(0, _originReturnType.length - 1);
    }
    return _originReturnType;
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
        .callback
        ?.arguments;
    return args != null && args.length == 1 ? args[0]!.name : '';
  }

  bool get isSuccessCallbackMultiArgs {
    ArgumentEntity? arg = arguments.singleWhere(
      (element) => element.name == 'success',
    );
    return arg.callback!.arguments.length > 1;
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
