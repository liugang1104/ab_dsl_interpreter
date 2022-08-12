class EnumEntity {
  String name;
  String plainString;

  EnumEntity({this.name = '', this.plainString = ''});

  factory EnumEntity.fromJson(Map<String, dynamic> json) {
    return EnumEntity(
        name: json['name'] ?? '', plainString: json['plainString'] ?? '');
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

class UseCaseClass {
  String plainString;
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
    this.plainString = '',
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
      plainString: map['plainString'] ?? '',
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

  final String originString;
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
    this.originString = '',
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
        originString: map['originString'] ?? '',
        platform: map['platform'] ?? "",
        methodName: map['methodName'] ?? "",
        returnType: map['returnType'] ?? "",
        nullFlag: map['nullFlag'] ?? '',
        isStatic: map['isStatic'] ?? false,
        arguments: ((map['arguments'] ?? []) as List)
            .map((e) => ArgumentEntity.fromJson(e))
            .toList(),
        deprecated: map['deprecated'] ?? "",
        comments: (map['comments'] ?? []).cast<String>());
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

  // 不带Future 和 ？的返回值类型
  String _syncReturnType = '';
  String get syncReturnType {
    if (_syncReturnType.isNotEmpty) {
      return _syncReturnType;
    }
    _syncReturnType = returnType;
    if (_syncReturnType.startsWith('Future')) {
      _syncReturnType =
          _syncReturnType.substring(7, _syncReturnType.length - 1);
    }
    return _syncReturnType;
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

  // 方法注释
  String get commentString => comments.join('\n');

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
    List<ArgumentEntity?>? args = arguments
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

class UseCaseEntity {
  List<EnumEntity> enums = [];
  List<UseCaseMethod> callbacks = [];
  List<UseCaseClass> classes = [];
  List<UseCaseMethod> typedefCallbacks = [];

  UseCaseEntity.fromJson(Map<String, dynamic> json) {
    classes = ((json['classes'] ?? []) as List)
        .map((e) => UseCaseClass.fromMap(e))
        .toList();
    enums = ((json['enums'] ?? []) as List)
        .map((e) => EnumEntity.fromJson(e))
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
