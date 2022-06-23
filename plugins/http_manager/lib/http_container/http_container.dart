import 'dart:convert';

/// 请求包含体
abstract class HttpContainer {
  /// 请求URL
  String get url => "";

  /// 基础地址
  String? baseAddress;

  /// 自定义URL
  String? customUrl;

  /// 请求参数
  Map<String, dynamic> queryParameters = {};

  /// 请求方式
  String get method;

  /// 存储地址
  String? savePath;

  /// 是否是文件
  bool isFile = false;

  /// 请求体
  dynamic body;

  /// 解析方式
  Encoding? get encoding => null;

  /// 请求头
  Map<String, String>? header = {};

  /// 规避dio encode queryParameter
  bool get needJoinQueryParameterBySelf => false;

  /// case oauth need custom
  String get queryParametersStr {
    List keys = queryParameters.keys.toList();
    String? str = keys
        .map((key) {
          var value = queryParameters[key];
          return "$key=$value";
        })
        .toList()
        .join("&");
    return str.isEmpty ? "" : ("?" + str);
  }

  /// 归属
  int? beLongTo;

  /// 请求标识
  int identify = -1;

  ///  重试次数
  int? retryTimes;

  HttpContainer([this.beLongTo]);
}

/// pos 请求
const String POST = "POST";
/// pos 请求
const String GET = "GET";
/// put 上传
const String PUT = "PUT";
/// delete 删除
const String DELETE = "DELETE";
/// 挂载包
abstract class HttpTickContainer extends HttpContainer with _BaseBehavior {
  HttpTickContainer([int? beLongTo]) : super(beLongTo);

  /// 请求方式
  String get method => GET;

  /// 超期时间
  DateTime? expireTime;

  /// 是否为Oauth 模式
  bool get isOauth => true;

  @override
  void initDataWith(
      {Map<String, String>? header, body, Map<String, dynamic>? queryParameter, String? customUrl}) {
    this.header = header ?? {};
    this.body = body;
    this.queryParameters = queryParameter ?? {};
    this.customUrl = customUrl;
    this.identify = this.hashCode;
  }

  String? savePath = "";

  /// 获取本地数据
  String get getKey => this.url;
}

/// 基础能力
mixin _BaseBehavior {
  /// 数据初始化
  void initDataWith(
      {Map<String, String>? header,
        dynamic body,
        Map<String, dynamic>? queryParameter}) {}

  /// 获取本地数据
  String get getKey {
    return "";
  }
}

/*
oauth 请求 token  请求体
--------------------------------------------------------
{
"client_id": "b93543b5-15b5-11ea-9583-000c29026700",
"client_secret": "secret",
"grant_type": "password",
"username": "18381333318",
"password": "hw123456",
}

请求头
{
"Content-Type": "application/x-www-form-urlencoded"
}
--------------------------------------------------------
 */


/*
oauth  刷新token 请求体
--------------------------------------------------------
{
"grant_type":"refresh_token",
"refresh_token":"542955cad44f3d9337cb5a41c16c91c3d91a1718e23abb7470501024d6b61830"
}

请求头
{
"Authorization" : ""
}
--------------------------------------------------------
 */



/*
oauth 数据请求 请求头
--------------------------------------------------------
{
 "authorization": "Bearer token"
}
--------------------------------------------------------
*/
