import 'dart:async';
import 'dart:convert';

import '../cache_manager/cache_manager.dart';
import '../http_manager/http_manager.dart';
import '../http_config/http_config.dart';
// import '../connectivity/connectivity.dart';
import '../http_container/http_container.dart';
import '../http_result_container/http_result_container.dart';
import '../client/client.dart';
import '../plugin_key/plugin_key.dart';
import '../event_notify/event_notify.dart';
import '../exception_collect/exception_collect.dart';
import '../refresh_unit/token_refresh_unit.dart';

/// 请求管道
class HttpMidBuffer {
  /// 实例
  static HttpMidBuffer? _buffer;

  /// 获取实例
  static HttpMidBuffer get buffer => _buffer!;

  /// 禁止外部初始化
  HttpMidBuffer._();

  /// 任务集
  Map<String, HttpTickContainer Function()> _taskMount = {};

  /// 端
  ClientData? _clientData;

  /// oauth 配置
  late _MiniConfig _config;

  /// 管理
  CacheBase? _cache;

  /// 事件监听
  EventNotifyClass? _eventListener;

  /// 异常信息
  ExceptionCollectAbstract? _exceptionCollect;

  /// 获取Ip
  String get ip => HttpManager.manager.ip;

  /// 获取 端口
  String get port => HttpManager.manager.port;

  /// 获取 token
  String get accessToken => _clientData?.accessToken ?? "";

  /// 刷新 token
  String get refreshToken => _clientData?.refreshToken ?? "";

  /// 作用域
  List<String> get scopes => _clientData?.scopes ?? [];

  /// 超时时间
  DateTime get expireDateTime => _clientData?.expireInTime ?? DateTime.now();

  /// 最后一次刷新时间
  DateTime? _lastRefreshTime;

  /// 启动
  static Future<void> setUpMidBuffer({HttpConfig? config,
    bool connectivity = false,
    void Function()? connectivityChange,
    CacheBase? cache,
    ClientData? clientData, EventNotifyClass? eventListener,
    ExceptionCollectAbstract? exceptionCollect}) async {
    if (_buffer == null) {
      _buffer = HttpMidBuffer._();
      _buffer!._setConfig(config);
      /// 配置请求管理
      HttpManager.setUpNetManager(config: config);
    }else {
      if (config != null) {
        /// 更新配置
        HttpManager.manager.updateConfig(config: config);
        _buffer!._setConfig(config);
      }
    }

    // if (cache == null) {
    //   /// 启动本地缓存
    //   await CacheManager.setUpCacheManager();
    //   _buffer!._cache = CacheManager.manager;
    // } else {
    //   _buffer!._cache = cache;
    // }

    /// token管理器
    if (clientData != null)
      _buffer!._clientData = clientData;
    else
      _buffer!._clientData = ClientDataContainer();

    /// 添加事件监听
    if (eventListener != null)
      _buffer!._eventListener = eventListener;
    else
      _buffer!._eventListener = EventNotifyListener();

    // if (connectivity)
    //
    //   /// 监听网络状态
    //   await ConnectivityManager.instance
    //       .startListenNetWorkState(connectivityChange);
    /// 数据异常
    if (exceptionCollect != null) {
      _buffer!._exceptionCollect = exceptionCollect;
    }
    return null;
  }

  /// 配置文件
  void _setConfig(HttpConfig? config) {
    _config = _MiniConfig(
        clientId: config?.clientId,
        clientSecret: config?.clientSecret,
        grantType: config?.grantType,
        enableOauth: config?.enableOauth,
        tokenRefreshInterval: config?.tokenRefreshInterval,
        unit: config?.refreshUnit,
        enableOperationRecord: config?.enableOperationRecord
    );
  }

  /// 添加任务(挂载)
  void addTickContainer(HttpTickContainer Function() container, String key) {
    _taskMount[key] = container;
  }

  /// 启动task mount
  void setUpTaskMount(Map<String, HttpTickContainer Function()> map) {
    _taskMount = {};
    _taskMount = map;
  }

  /// 添加任务
  void addTickContainers(Map<String, HttpTickContainer Function()> ticks) {
    _taskMount.addAll(ticks);
  }

  /// 移除
  void removeTick(String key) {
    _taskMount.remove(key);
  }

  /// 更新配置
  void updateMidBuffer({HttpConfig? config}) {
    _setConfig(config);
    HttpManager.manager.updateConfig(config: config);
  }

  /// 接口统一接口
  Future<HttpResultContainer> requestWithParameter(String path,
      Map<String, dynamic> para, {void Function(int? token)? cancelToken}) async {
    /// 获取原始参数 header
    Map<String, String>? header = para[HttpPluginKey.HEADER];
    /// 获取原始参数 body
    dynamic body = para[HttpPluginKey.BODY];

    /// 获取原始参数 parameter
    Map<String, dynamic>? queryParameter = para[HttpPluginKey.QUERYPARAMETER];

    /// 自定义URL
    String? customUlr = para[HttpPluginKey.CUSTOMURL];

    /// 取出 Container
    HttpTickContainer? container = _taskMount[path]?.call();
    /// 返回取消标识符
    _c(cancelToken, container?.identify);
    if (container == null) {
      /// 功能未发现
      HttpResultContainer result = HttpResultContainer(404, err: "未发现接口功能: $path", isSuccess: false);
      return Future.value(result);
    } else { // if (!ConnectivityManager.instance.none)
      // DateTime.now().isAfter(container.expireTime) && !ConnectivityManager.instance.none
      if (container.isOauth && _buffer!._config.enableOauth!) {
        return _oauthRequest(key: path,
            container: container,
            customUrl: customUlr,
            header: header,
            body: body,
            queryPara: queryParameter);
      }

      /// 数据返回
      return _requestWithPara(key: path,
          container: container,
          body: body,
          header: header,
          queryPara: queryParameter,
          customUrl: customUlr);
    }
    // else {
    //   return Future.value(HttpResultContainer(400, err: "设备网络不可用", isSuccess: false));
    // }
  }

  /// 下载
  Future<HttpResultContainer> downloadWithParameter(String path, Map<String, dynamic> para, String savePath,
      {void Function(int count, int amount)? process, void Function(int? token)? cancelToken}) async{
    /// 获取原始参数 header
    Map<String, String>? header = para[HttpPluginKey.HEADER];

    /// 获取原始参数 body
    dynamic body = para[HttpPluginKey.BODY];

    /// 获取原始参数 parameter
    Map<String, dynamic>? queryParameter = para[HttpPluginKey.QUERYPARAMETER];

    /// 自定义URL
    String? customUlr = para[HttpPluginKey.CUSTOMURL];

    /// 取出 Container
    HttpTickContainer? container = _taskMount[path]?.call();

    if (container == null) {
      return Future.value(
          HttpResultContainer(404, err: "未发现刷新token功能", isSuccess: false));
    }

    if (container.isOauth && _buffer!._config.enableOauth!) {
      /// 如果有锁 等待解锁
      if (_lock != null && !await _lock!)
        return Future.value(HttpResultContainer(401,
            err: "oauth 刷新失败", isSuccess: false, data: "oauth 刷新失败"));
      header = _addOauth(header);
    }
    container.initDataWith(header: header, body: body, queryParameter: queryParameter, customUrl: customUlr);
    /// 返回取消标识符
    _c(cancelToken, container.identify);
    return _downloadRequest(path, container, savePath, process: process!);
  }

  /// 上传
  Future<HttpResultContainer> uploadWithParameter(String path, Map<String, dynamic> para,
      {void Function(int count, int amount)? process, void Function(int? token)? cancelToken}) async{
    /// 获取原始参数 header
    Map<String, String> header = para[HttpPluginKey.HEADER];

    /// 获取原始参数 body
    dynamic body = para[HttpPluginKey.BODY];

    /// 获取原始参数 parameter
    Map<String, dynamic>? queryParameter = para[HttpPluginKey.QUERYPARAMETER];

    /// 自定义URL
    String? customUlr = para[HttpPluginKey.CUSTOMURL];

    /// 取出 Container
    HttpTickContainer? container = _taskMount[path]?.call();

    if (container == null) {
      return Future.value(
          HttpResultContainer(404, err: "未发现刷新token功能", isSuccess: false));
    }

    if (container.isOauth && _buffer!._config.enableOauth!) {
      /// 如果有锁 等待解锁
      if (_lock != null && !await _lock!)
        return Future.value(HttpResultContainer(401,
            err: "oauth 刷新失败", isSuccess: false, data: "oauth 刷新失败"));
      header = _addOauth(header);
    }
    container.initDataWith(header: header, body: body, queryParameter: queryParameter, customUrl: customUlr);
    /// 返回取消标识符
    _c(cancelToken, container.identify);
    return _uploadRequest(path, container, process: process);
  }

  /// 取消所有请求
  void cancelAllRequest(){
    HttpManager.manager.cancelAllRequest();
  }

  /// 初始化 oauth
  Future<HttpResultContainer> initializeOauth(Map<String, dynamic> para) async {
    /// 获取请求
    HttpTickContainer? container = _taskMount[HttpPluginKey.ACCESS_PASSWORD]?.call();

    if (container == null) {
      return Future.value(HttpResultContainer(400, err: "未发现Oauth初始化功能"));
    }
    /// 重新允许请求
    _lock = null;

    /// 获取原始参数 header
    Map<String, String>? header = para[HttpPluginKey.HEADER];

    /// 获取原始参数 body
    dynamic body = para[HttpPluginKey.BODY];

    if (header == null || header.isEmpty) {
      header = {
        "content-type": "application/x-www-form-urlencoded",
        "Authorization":
        "${_basicAuthHeader(_config.clientId!, _config.clientSecret!)}"
      };
    } else if (!header.containsKey("content-type")) {
      header["content-type"] = "application/x-www-form-urlencoded";
      header["Authorization"] =
      "${_basicAuthHeader(_config.clientId!, _config.clientSecret!)}";
    }

    if (body == null) {
      body = {
        "client_id": "${_config.clientId}",
        "client_secret": "${_config.clientSecret}",
        "grant_type": "${_config.grantType}",
      };
    } else if (body is Map) {
      body["client_id"] = "${_config.clientId}";
      body["client_secret"] = "${_config.clientSecret}";
      body["grant_type"] = "${_config.grantType}";
    }
    container.initDataWith(header: header, body: body);

    /// 等待请求结果
    HttpResultContainer result = await _request(container, HttpPluginKey.ACCESS_PASSWORD);
    if (result.statusCode == 200) {
      /// 如果 请求成功
      _updateClientData(result.data);
      _cacheData(HttpPluginKey.ACCESS_PASSWORD, _clientData!.toJson());
      return Future.value(result);
    } else {
      return Future.value(result);
    }
  }

  Timer? _timer;
  /// 更新客户端数据
  void _updateClientData(Map<String, dynamic> json) {
    _clientData = ClientDataContainer.fromJson(json, _config.unit);
    _updateTimer(_config.unit, _clientData!.expireIn!);
  }

  /// 更新timer 刷新时间
  void _updateTimer(RefreshUnit? _n, int expireIn){
    Duration duration;
    switch(_n ?? RefreshUnit.second){
      case RefreshUnit.day:
        duration = Duration(days: expireIn);
        break;
      case RefreshUnit.hour:
        duration = Duration(hours: expireIn);
        break;
      case RefreshUnit.minute:
        duration = Duration(minutes: expireIn);
        break;
      case RefreshUnit.millisecond:
        duration = Duration(milliseconds: expireIn);
        break;
      case RefreshUnit.microsecond:
        duration = Duration(microseconds: expireIn);
        break;
      default:
        duration = Duration(seconds: expireIn);
        break;
    }
    if (_clientData!.expireInTime != null && _clientData!.expireInTime!.isAfter(DateTime.now())) {
      duration = expireDateTime.difference(DateTime.now());
    }
    /// 选择更新一次刷新一次
    if (_timer == null) {
      debugLog("http == plugin ===== initializeTimer ========onTime ${DateTime.now()}==== expire in ${DateTime.now().add(duration)} ===");
      _initializeTimer(duration);
    }else {
      cancelTimer();
      debugLog("http == plugin ===== initializeTimer ========onTime ${DateTime.now()}==== expire in ${DateTime.now().add(duration)} ===");
      _initializeTimer(duration);
    }
  }

  /// 停止计时
  void cancelTimer(){
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  /// 初始化timer
  void _initializeTimer(Duration duration){
    _timer = Timer.periodic(duration, (timer) {
      debugLog("http == plugin ===== token refresh ========onTime ${DateTime.now()}=======");
      refresh();
    });
  }

  /// 更新client data
  bool updateClientDataWith(ClientData clientData) {
    Map<String, dynamic> json = clientData.toJson();
    _updateClientData(json);
    return _clientData!.isLegal;
  }

  void cleanClientData(){
    _clientData = null;
    // _updateClientData({});
  }
  /// 通过cache 获取
  bool updateClientDataWithCache() {
    String value = "";

    /// 从 refresh 里面拿
    HttpTickContainer? container = _taskMount[HttpPluginKey.REFRESH_PASSWORD]?.call();
    String? data = _cache?.getValueForKey(container?.getKey ?? "");
    if (data != null && data.isNotEmpty) {
      value = data;
    } else {
      /// 如果refresh 里为空 从 access 里面拿
      HttpTickContainer? container = _taskMount[HttpPluginKey.ACCESS_PASSWORD]?.call();
      data = _cache?.getValueForKey(container?.getKey ?? "");
      if (data != null && data.isNotEmpty) {
        value = data;
      }
    }

    /// 解析
    Map<String, dynamic>? json;
    try {
      json = jsonDecode(value);
    } catch (_) {}

    /// 为空  返回失败
    if (json == null || json.isEmpty)
      return false;
    else

      /// 否则更新client
      _updateClientData(json);

    /// 如果client 是 有效的 返回true
    if (_clientData!.isLegal) {
      return true;
    }

    /// client  更新失败 返回false
    return false;
  }

  /// ---------- 私有功能 ------------------------

  /// 刷新 token
  Future<HttpResultContainer> refresh() async {
    Map<String, String> header = {
      "Authorization":
      "${_basicAuthHeader(_config.clientId!, _config.clientSecret!)}",
      "content-type": "application/x-www-form-urlencoded"
    };
    Map body = {
      "grant_type": "refresh_token",
      "refresh_token": "${_clientData!.refreshToken}"
    };

    HttpTickContainer? container = _taskMount[HttpPluginKey.REFRESH_PASSWORD]?.call();
    if (container == null) {
      return Future.value(
          HttpResultContainer(404, err: "未发现刷新token功能", isSuccess: false));
    }
    container.initDataWith(header: header, body: body);
    HttpResultContainer result = await _request(container, HttpPluginKey.REFRESH_PASSWORD);
    if (result.statusCode == 200) {
      _updateClientData(result.data);
      _cacheData(HttpPluginKey.REFRESH_PASSWORD, _clientData!.toJson());
      _eventListener?.onTokenRefreshSuccess();
    } else {
      _eventListener?.onTokenRefreshFailure();
    }
    return Future.value(result);
  }

  /// 保存本地数据
  void _cacheData(String key, Map<String, dynamic> json) {
    String value = "";
    try {
      value = jsonEncode(json);
    } catch (_) {}
    _cache?.setValueForKey(key, value);
  }

  /// 锁
  Future<bool>? _lock;

  /// oauth 更新
  Future<HttpResultContainer> _oauthRequest({required String key, required HttpTickContainer container,
    Map<String, String>? header,
    dynamic body,
    Map<String, dynamic>? queryPara, String? customUrl}) async {
    /// 检查有无token 管理
    if (_clientData == null)
      return Future.value(HttpResultContainer(400,
          err: "oauth 尚未初始化", isSuccess: false, data: "oauth 尚未初始化"));

    /// 验证token 是否超期
    if (_clientData!.isExpire) {
      HttpResultContainer result = await refresh();
      if (result.statusCode != 200) {
        return Future.value(HttpResultContainer(result.statusCode,
            err: result.err, isSuccess: result.isSuccess, data: "oauth 刷新失败"));
      }
    }

    /// 如果有锁 等待解锁
    if (_lock != null && !await _lock!)
      return Future.value(HttpResultContainer(401,
          err: "oauth 刷新失败", isSuccess: false, data: "oauth 刷新失败"));

    /// 请求结果
    var result;
    /// 请求
    Future<HttpResultContainer> onRequest(){
      header = _addOauth(header);
      return _requestWithPara(key: key ,container: container, body: body, header: header, queryPara: queryPara, customUrl: customUrl);
    }

    /// 返回请求结果
    result = await onRequest();

    /// 如果发现未授权
    if (result.statusCode == 401 || result.statusCode == 405 || result.statusCode == 403) {
      if(_lastRefreshTime == null || DateTime.now().difference(_lastRefreshTime!).inMinutes > _config.tokenRefreshInterval!) {
        /// 如果有锁 等待解锁
        if (_lock != null){
          /// 是否刷新成功
          bool isSuccess = await _lock!;
          if (isSuccess) {
            result = await onRequest();
          }
        }else {
          /// 加锁
          Completer<bool> completer = Completer<bool>();
          _lock = completer.future;

          /// 刷新token 验证是否token 已被移除
          var refreshResult = await refresh();
          /// 重置上一次的刷新时间
          _lastRefreshTime = DateTime.now();

          if (refreshResult.statusCode == 200) {
            /// 解锁
            completer.complete(true);
            _lock = null;
            /// 未被移除则再次请求
            result = await onRequest();
          } else {
            /// 解锁
            completer.complete(false);
            _lock = null;
          }
        }
      }else {
        result = await onRequest();
      }
    }
    return Future.value(result);
  }

  /// 添加oauth
  Map<String, String> _addOauth(Map<String, String>? header){
    /// 添加请求头
    if (header == null || header.isEmpty) {
      header = {"authorization": "Bearer ${_clientData!.accessToken}"};
    } else {
      header["authorization"] = "Bearer ${_clientData!.accessToken}";
    }
    return header;
  }

  /* mark
  * 基础请求方式**/

  /// 请求
  Future<HttpResultContainer> _requestWithPara({required String key, required HttpTickContainer container,
    Map<String, String>? header,
    dynamic body,
    Map<String, dynamic>? queryPara, String? customUrl}) {
    /// 配置参数
    container.initDataWith(
        header: header,
        body: body,
        queryParameter: queryPara,
        customUrl: customUrl);

    /// 返回服务器数据
    return _request(container, key);
  }

  /// 网络数据请求
  Future<HttpResultContainer> _request(HttpContainer container, String key) async {
    dynamic result;
    _operationCollection(key: key, container: container);
    try {
      result = await (HttpManager.manager.requestWith(container)..then((value) {
        _collectException(value: value, key: key, container: container);
      }));
    } catch (e) {
      result = e as HttpResultContainer;
      _collectException(value: result, key: key, container: container);
    }
    return Future.value(result);
  }

  /// 文件下载
  Future<HttpResultContainer> _downloadRequest(String key, HttpContainer container, String savePath, {void Function(int count, int amount)? process}) async {
    dynamic result;
    _operationCollection(key: key, container: container);
    try {
      result = await (HttpManager.manager.downloadWith(container, savePath, process: process)..then((value) {
        _collectException(value: value, key: key, container: container);
      }));
    } catch (e) {
      result = e as HttpResultContainer;
      _collectException(value: result, key: key, container: container);
    }
    return Future.value(result);
  }

  /// 文件上传
  Future<HttpResultContainer> _uploadRequest(String key, HttpContainer container, {void Function(int count, int amount)? process}) async{
    dynamic result;
    _operationCollection(key: key, container: container);
    try {
      result = await (HttpManager.manager.uploadWith(container, process: process)..then((value) {
        _collectException(value: value, key: key, container: container);
      }));
    } catch (e) {
      result = e as HttpResultContainer;
      _collectException(value: result, key: key, container: container);
    }
    return Future.value(result);
  }

  /// 取消请求
  void cancelRequestWidth(int identify) {
    HttpManager.manager.cancelRequestWith(identify);
  }

  /// 返回取消token
  void _c(void Function(int?)? cancelToken, int? key){
    if (cancelToken != null)
      cancelToken(key);
  }

  /// 收集异常
  void _collectException({required HttpResultContainer value, required String key, required HttpContainer container}){
    if (_exceptionCollect != null && value.statusCode != 200) {
      _exceptionCollect!.addException({
        "key": key,
        "value": {
          HttpPluginKey.HEADER: container.header,
          HttpPluginKey.BODY: container.body,
          HttpPluginKey.QUERYPARAMETER: container.queryParameters,
          HttpPluginKey.CUSTOMURL: container.customUrl
        },
        "exceptionTime": DateTime.now().toIso8601String(),
        "exceptionReason": value.err
      });
    }
  }

  /// 操作记录
  void _operationCollection({required String key, required HttpContainer container}){
    if (_exceptionCollect != null && _config.enableOperationRecord!) {
      _exceptionCollect!.addOperation({
        "key": key,
        "value": {
          HttpPluginKey.HEADER: container.header,
          HttpPluginKey.BODY: container.body,
          HttpPluginKey.QUERYPARAMETER: container.queryParameters,
          HttpPluginKey.CUSTOMURL: container.customUrl
        },
        "operateTime": DateTime.now().toIso8601String()
      });
    }
  }

  /// 刷新token 请求头
  String _basicAuthHeader(String identifier, String secret) {
    var userPass = Uri.encodeFull(identifier) + ":" + Uri.encodeFull(secret);
    return "Basic " + base64Encode(ascii.encode(userPass));
  }
}

/// mini config
class _MiniConfig {
  /// 客户端ID
  final String? clientId;

  /// 客户端秘钥
  final String? clientSecret;

  /// 授权类型
  final String? grantType;

  /// 是否启动oauth
  final bool? enableOauth;

  /// 刷新间隔
  final RefreshUnit? unit;

  /// 记录文件
  final bool? enableOperationRecord;

  /// token 刷新间隔
  final int? tokenRefreshInterval;

  _MiniConfig(
      {this.clientId, this.clientSecret, this.grantType, this.tokenRefreshInterval,
        this.enableOauth, this.unit, this.enableOperationRecord});
}

void Function(String) debugLog = (msg) {
  assert(() {
    print("$msg");
    return true;
  }()); //  if (kDebugMode) print("$msg");
};