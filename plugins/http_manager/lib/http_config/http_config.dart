// import 'package:dio/dio.dart';
import '../refresh_unit/token_refresh_unit.dart';
import '../response_deal/error_deal.dart';

class HttpConfig {
  /// 请求超时
  final int timeOut;

  /// 连接超时
  final int connectTimeOut;

  /// 关闭时间
  final int slaveCloseTime;

  /// 最大线程
  final int maxSlave;

  /// 最大下载线程
  final int maxLongRunningSlave;

  /// ip 地址
  final String? ip;

  /// 端口
  final String? port;

  /// 客户端ID
  final String? clientId;

  /// 客户端秘钥
  final String? clientSecret;

  /// 授权类型
  final String? grantType;

  /// 是否启动oauth
  final bool enableOauth;

  /// 是否是开发环境
  final bool isDevelop;

  /// 拦截地址
  final String? proxyUrl;

  /// token 刷新时间间隔单位
  final RefreshUnit refreshUnit;

  /// 记录文件
  final bool enableOperationRecord;

  /// token 刷新间隔(单位: 分钟)
  final int tokenRefreshInterval;

  // /// 注入cookie
  // final Interceptor? interceptor;

  /// 是否允许重定向
  final bool enableRedirect;

  /// 忽略重试
  final List<int> statusCodeIgnoreRetry;

  /// 错误处理
  final ErrorDeal errorDeal;

  const HttpConfig({this.timeOut: 30000,
    this.connectTimeOut: 30000,
    this.slaveCloseTime: 600,
    this.maxSlave: 5,
    this.maxLongRunningSlave: 3,
    this.tokenRefreshInterval: 1,
    this.ip,
    this.port,
    this.clientSecret,
    this.clientId,
    this.grantType,
    this.proxyUrl,
    this.enableOauth: false,
    this.enableOperationRecord: false,
    this.isDevelop: false,
    this.enableRedirect: true,
    this.refreshUnit = RefreshUnit.second,
    this.errorDeal: const ErrorDealDefault(),
    // this.interceptor,
    this.statusCodeIgnoreRetry: const <int>[]
  });
}