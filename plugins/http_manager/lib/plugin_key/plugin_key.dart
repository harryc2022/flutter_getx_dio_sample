

class HttpPluginKey {
  /// 初始化 header 参数
  static const String HEADER = "header";

  /// 初始化 body 参数
  static const String BODY = "body";

  /// 初始化 query parameter 参数
  static const String QUERYPARAMETER = "query_parameter";
  /// 自定义URL
  static const String CUSTOMURL = "custom_url";

  /*
    插件能力保留字段
  */
  /// 刷新token
  static const String REFRESH_PASSWORD = "refreshToken_password";

  /// 获取token
  static const String ACCESS_PASSWORD = "accessToken_password";
}