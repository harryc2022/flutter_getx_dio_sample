# httpplugin

http请求插件 
依赖于 dio，connectivity，shared_preferences

## Getting Started

启动中间层
HttpConfig  配置文件
配置超时时间、连接超时时间、线程关闭时间、最大线程数量、ip地址、端口
HttpConfig(
      timeOut: 30000,
        connectTimeOut: 30000,
        slaveCloseTime: 600,
        maxSlave: 3, ip: "192.168.1.1", port: "30309")
请求挂载
HttpTickContainer

/// 基础能力
mixin _BaseBehavior {
  /// 数据初始化
  void initDataWith(Map<String, dynamic> data);

  /// 获取本地数据
  String getKey();
}

/// 请求URL
  String get url => "";

  /// 基础地址
  String baseAddress;

  /// 请求参数
  Map<String, dynamic> get queryParameters => {};

  /// 请求方式
  String get method => "GET";

  /// 请求体
  dynamic get body => null;

  /// 解析方式
  Encoding get encoding => null;

  /// 请求头
  Map<String, String> get header => null;

数据管理

abstract class CacheBase {
  /// 保存数据
  void setValueForKey(String key, String value);
  /// 获取数据
  String getValueForKey(String key);
}

/// 启动网络管理
static Future<void> setUpMidBuffer(
      {HttpConfig config,
      bool connectivity = false,
      void Function() connectivityChange,
      CacheBase cache})