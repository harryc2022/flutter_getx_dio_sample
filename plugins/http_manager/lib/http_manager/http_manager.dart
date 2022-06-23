import 'dart:async';
import 'dart:io';

import 'package:alog/alog.dart';
/// 三方库
import 'package:dio/dio.dart';

/// 本地文件
import '../http_container/http_container.dart';
import '../http_config/http_config.dart';
import '../http_result_container/http_result_container.dart';
import '../response_deal/error_deal.dart';

/// HTTP 请求管理器
class HttpManager {
  /// 实例
  static HttpManager? _manager;

  /// 单例共享
  static HttpManager get manager => _shareInstance();

  /// 配置文件
  HttpConfig? _config;

  /// 获取Ip
  String get ip => _config?.ip ?? "";

  /// 获取 端口
  String get port => _config?.port ?? "";

  /// 请求队列
  List<HttpContainer> _requests = [];

  /// 下载队列
  List<HttpContainer> _downLoadRequests = [];

  /// 上传队列
  List<HttpContainer> _upLoadRequests = [];

  /// 下载进度表 请求identify: 下载进度通知
  Map<int, void Function(int count, int amount)> _downLoadProcess = {};

  /// 上传进度表 请求identify: 上传进度通知
  Map<int, void Function(int count, int amount)> _upLoadProcess = {};

  /// 结果集 请求identify: 请求结果
  Map<int, Completer<HttpResultContainer>> _resultsMap = {};

  /// 工作 slave.identify: slave
  Map<int, _Slave> _slaveMap = {};

  /// 发送端口 slave.identify: slave sendPort
  Map<int, StreamController> _slaveSend = {};

  /// 接口工作线程集 slave.identify: 简易请求(identify, belongTo)
  Map<int, _SampleContainer> _slaveContainer = {};

  /// 下载的线程 slave.identify: 请求identify
  Map<int, int> _longRunningSlave = {};
  /// 任务
  final _TaskNotification _task = _TaskNotification();

  /// 是否已达到最大数
  bool get _isMax =>
      _slaveMap.keys
          .toList()
          .length >= _config!.maxSlave;

  /// 任务分配锁
  Future<Null>? _assignedTaskLock;

  /// 找到能工作的 线程
  _CanWork get _canWorkSlave {
    int? _slaveIdentify;
    _slaveMap.forEach((identify, slave) {
      if (_slaveIdentify == null && slave.canWork) {
        _slaveIdentify = identify;
      }
    });
    return _CanWork(_slaveIdentify != null, slaveIdentify: _slaveIdentify);
  }
  /// 能够执行耗时操作
  bool get _canAsLongRunning => _longRunningSlave.length <= _config!.maxLongRunningSlave;

  /// 启动 管理端
  static void setUpNetManager({HttpConfig? config}) {
    if (_manager == null) {
      if (config == null) config = HttpConfig();
      _manager = HttpManager._internal(config: config);
    }
  }

  /// 单例初始化
  static HttpManager _shareInstance() {
    return _manager!;
  }

  /// 初始化  禁止外部调用初始化
  HttpManager._internal({HttpConfig? config}) {
    this._config = config;
    _init();
  }

  /// 更新配置
  void updateConfig({HttpConfig? config}) {
    this._config = config;
    this._slaveSend.entries.forEach((element) {
      int identify = element.key;
      /// 暂不锁定
      // _slaveMap[identify].startLock();
      element.value.add(_ConfigUpdateSignal(
        identify,
        proxyUrl: _config?.proxyUrl,
        status: _config?.statusCodeIgnoreRetry ?? [],
        isDevelop: _config?.isDevelop,
        timeOut: _config?.timeOut,
        connectTimeOut: _config?.connectTimeOut,
        // interceptor: _config?.interceptor
      ));
    });
  }

  _init() {
    _task.listen((msg) {
      if (msg is _SlaveClose) {
        /// 如果线程关闭了  则 移除
        if (_slaveMap.containsKey(msg.identify)) {
          print("msg.identify: ${msg.identify} slave work over ---  撒由啦啦");
          _slaveMap.remove(msg.identify);
          _slaveSend.remove(msg.identify);
          return;
        }
        return;
      }

      /// 线程初始化
      if (msg is _SlaveSetUp) {
        _slaveSend[msg.identify] = msg.send;
        msg.send.add(_InitDio(msg.identify, enableRedirect: _config?.enableRedirect,
            connectTimeOut: _config!.connectTimeOut, timeOut: _config!.timeOut,
            status: _config?.statusCodeIgnoreRetry ?? [],
            isDevelop: _config?.isDevelop, proxyUrl: _config?.proxyUrl,
        // interceptor: _config?.interceptor
        ));
        return;
      }

      /// 初始化完成
      if (msg is _SlaveInitComplete) {
        /// 初始化完成  解锁
        _slaveMap[msg.identify]!.endLock();

        /// 开始工作
        _slaveWorkHard(msg.identify, msg.send, canLongRunning: _canAsLongRunning);
        return;
      }

      /// 下载完成
      if (msg is _DownloadRequestEndSignal) {
        Completer<HttpResultContainer>? completer = _resultsMap.remove(msg.requestIdentify);
        _resultsMap.remove(msg.requestIdentify);
        if (msg.error != null) {
          HttpResultContainer container = HttpResultContainer(msg.statusCode,
              err: msg.error, isSuccess: false);
          completer?.completeError(container);
        } else {
          HttpResultContainer container = HttpResultContainer(msg.statusCode, data: msg.data, headers: msg.headers);
          completer?.complete(container);
        }
        /// 线程解锁
        _slaveMap[msg.identify]!.endLock();

        /// 工作移除
        _slaveContainer.remove(msg.identify);
        _longRunningSlave.remove(msg.identify);
        _downLoadProcess.remove(msg.identify);

        /// 开始工作
        _slaveWorkHard(msg.identify, msg.send, canLongRunning: _canAsLongRunning);
        return;
      }

      /// 下载进度通知
      if (msg is _DownloadProcessSignal) {
        var func = _downLoadProcess[msg.requestIdentify];
        if (func != null) {
          func(msg.count, msg.amount);
        }
        return;
      }

      /// 请求结束
      if (msg is _RequestEndSignal) {
        Completer<HttpResultContainer>? completer =
        _resultsMap.remove(msg.requestIdentify);
        if (msg.error != null) {
          HttpResultContainer container = HttpResultContainer(msg.statusCode,
              err: msg.error, isSuccess: false);
          completer?.completeError(container);
        } else {
          HttpResultContainer container =
          HttpResultContainer(msg.statusCode, data: msg.data);
          completer?.complete(container);
        }

        /// 线程解锁
        _slaveMap[msg.identify]!.endLock();

        /// 工作移除
        _slaveContainer.remove(msg.identify);

        /// 开始工作
        _slaveWorkHard(msg.identify, msg.send, canLongRunning: _canAsLongRunning);
        return;
      }

      if (msg is _UploadProcessSignal) {
        var func = _upLoadProcess[msg.requestIdentify];
        if (func != null) {
          func(msg.count, msg.amount);
        }
        return;
      }

      if(msg is _UploadRequestEndSignal) {
        Completer<HttpResultContainer>? completer = _resultsMap.remove(msg.requestIdentify);
        _resultsMap.remove(msg.requestIdentify);
        if (msg.error != null) {
          HttpResultContainer container = HttpResultContainer(msg.statusCode,
              err: msg.error, isSuccess: false);
          completer?.completeError(container);
        } else {
          HttpResultContainer container = HttpResultContainer(msg.statusCode, data: msg.data);
          completer?.complete(container);
        }
        /// 线程解锁
        _slaveMap[msg.identify]!.endLock();

        /// 工作移除
        _slaveContainer.remove(msg.identify);
        _longRunningSlave.remove(msg.identify);
        _upLoadProcess.remove(msg.identify);

        /// 开始工作
        _slaveWorkHard(msg.identify, msg.send, canLongRunning: _canAsLongRunning);
        return;
      }

      if (msg is _ConfigUpdateComplete) {
        /// 暂不做处理
        // /// 线程解锁
        // _slaveMap[msg.identify].endLock();
        // /// 开始工作
        // _slaveWorkHard(msg.identify, msg.sendPort, canLongRunning: _canAsLongRunning);
      }
    });

    /// 初始化一条线程
    _slaveInit(_task.send, true);
  }

  /// 开始请求
  Future<HttpResultContainer> requestWith(HttpContainer container) {
    _configContainerUrl(container);

    /// 加入请求标识
    _resultsMap[container.identify] = Completer<HttpResultContainer>();

    /// 找到可以工作的线程
    _CanWork slaveWork = _canWorkSlave;
    /// 如果有可以工作的
    if (slaveWork.canWork) {
      int identify = slaveWork.slaveIdentify!;
      _slaveMap[identify]!.startLock();
      StreamController send = _slaveSend[identify]!;
      _request(send, identify, container);
    } else {
      _requests.add(container);
      _tryInitSlave();
    }

    /// 返回结果
    return _resultsMap[container.identify]!.future;
  }

  /// 尝试初始化线程
  void _tryInitSlave(){
    if (_isMax) {
      /// 如果已经到了 最大化
    } else {
      /// 初始化
      _slaveInit(_task.send);
    }
  }

  HttpConfig? getConfig(){
    return _config;
  }

  /// 下载文件
  Future<HttpResultContainer> downloadWith(HttpContainer container, String savePath, {void Function(int count, int amount)? process}){
    _configContainerUrl(container);
    container.savePath = savePath;
    _resultsMap[container.identify] = Completer<HttpResultContainer>();
    _downLoadProcess[container.identify] = process ?? (_, __){};
    _CanWork slaveWork = _canWorkSlave;
    if (slaveWork.canWork) {
      if (_canAsLongRunning) {
        int identify = _canWorkSlave.slaveIdentify!;
        _slaveMap[identify]!.startLock();
        StreamController send = _slaveSend[identify]!;
        _downloadRequestWith(send, identify, container);
      }else {
        _downLoadRequests.add(container);
      }
    }else {
      _downLoadRequests.add(container);
      _tryInitSlave();
    }
    return _resultsMap[container.identify]!.future;
  }

  /// 上传文件
  Future<HttpResultContainer> uploadWith(HttpContainer container, {void Function(int count, int amount)? process}){
    _configContainerUrl(container);
    _resultsMap[container.identify] = Completer<HttpResultContainer>();
    _upLoadProcess[container.identify] = process ?? (_, __){};
    _CanWork slaveWork = _canWorkSlave;
    if (slaveWork.canWork) {
      if (_canAsLongRunning) {
        int identify = _canWorkSlave.slaveIdentify!;
        _slaveMap[identify]!.startLock();
        StreamController send = _slaveSend[identify]!;
        _uploadRequestWith(send, identify, container);
      }else {
        _upLoadRequests.add(container);
      }
    }else {
      _upLoadRequests.add(container);
      _tryInitSlave();
    }
    return _resultsMap[container.identify]!.future;
  }

  /// 取消所有请求
  void cancelAllRequest() {
    _requests = [];
    _slaveSend.forEach((key, value) {
      value.add(_SlaveCancel(msg: ""));
    });
    _longRunningSlave = {};
    _downLoadRequests = [];
    _upLoadRequests = [];
    _slaveContainer = {};
    _downLoadProcess = {};
    _upLoadProcess = {};
    _resultsMap = {};
  }

  /// 配置url
  void _configContainerUrl(HttpContainer container){
    if (_config!.port == null || _config!.port!.isEmpty) {
      /// 无端口配置设置
      container.baseAddress = _config!.ip;
    } else if (container.baseAddress == null || container.baseAddress!.isEmpty) {
      /// 配置 ip 地址
      container.baseAddress = _config!.ip! + ":" + _config!.port!;
    }
    /// 确保每个请求identify 不同 (由于设计原因identify 已经不相同)
    /// 目前 identify 为每个container的 hasCode
    // container.identify = _ContainerIdentifier().hashCode;
  }

  /// 取消请求
  void cancelRequestWith(int? identify) async{
    if (identify == null) {
      return;
    }
    /// 移除可能存在的数据
    _requests.removeWhere((e) => e.identify == identify);
    _upLoadProcess.remove(identify);
    _downLoadProcess.remove(identify);

    bool cancel = false;
    /// 移除已经在请求的
    _slaveContainer.forEach((key, value) {
      if (value.identify == identify) {
        cancel = true;
        _slaveSend[key]!.add(_SlaveCancel());
      }
    });
    _slaveContainer.removeWhere((key, value) => value.identify == identify);
    /// 移除未在请求的 并返回错误
    if (!cancel && _resultsMap.containsKey(identify)) {
      var completer = _resultsMap.remove(identify);
      completer!.complete(HttpResultContainer(-1, isSuccess: false, data: null, err: "用户取消请求"));
    }
  }

  /// 取消请求
  void cancelRequestWithPage(int? identify) async {
    if (identify == null) {
      return;
    }

    /// 开始取消请求 
    _slaveContainer.forEach((key, value) {
      if (value.belongTo == identify) {
        cancelRequestWith(value.identify);
      }
    });
  }

  /// 初始化线程
  void _slaveInit(StreamController send, [bool isOriginal = false]) {
    _Slave slave = _Slave(send,
        isOriginal: isOriginal, timeLimit: _config!.slaveCloseTime);
    _slaveMap[slave.identify] = slave;
  }

  /// 开始工作
  void _slaveWorkHard(int identify, StreamController send, {bool canLongRunning = false}) async {
    if(_requests.isEmpty && _downLoadRequests.isEmpty && _upLoadRequests.isEmpty) {
      return ;
    }
    await _waitingLock();
    print("the slave manager has start lock ------");
    Completer<Null> completer = _initAssignedLock();
    _Slave _slave = _slaveMap[identify]!;
    _slave.startLock();
    HttpContainer? netWorkContainer;
    if(_requests.isNotEmpty) {
      netWorkContainer = _requests.removeAt(0);
      _request(send, identify, netWorkContainer);
    }else if (canLongRunning && _upLoadRequests.isNotEmpty){
      netWorkContainer = _upLoadRequests.removeAt(0);
      _uploadRequestWith(send, identify, netWorkContainer);
    }else if (canLongRunning && _downLoadRequests.isNotEmpty) {
      netWorkContainer = _downLoadRequests.removeAt(0);
      _downloadRequestWith(send, identify, netWorkContainer);
    }
    if (netWorkContainer != null) {
      _slaveContainer[identify] = _SampleContainer(netWorkContainer.identify, netWorkContainer.beLongTo);
    }else {
      _slave.endLock();
    }
    _unLock(completer);
    print("the slave manager did end lock ------");
  }

  /// 上传
  void _uploadRequestWith(StreamController send, int identify, HttpContainer netWorkContainer){
    _UploadRequestStartSignal _uploadRequestStartSignal = _UploadRequestStartSignal(identify, netWorkContainer,
        isDevelop: _config!.isDevelop,
      errorDeal: _config?.errorDeal ?? ErrorDealDefault()
    );
    send.add(_uploadRequestStartSignal);
    _longRunningSlave[identify] = netWorkContainer.identify;
  }
  /// 下载
  void _downloadRequestWith(StreamController send, int identify, HttpContainer netWorkContainer){
    _DownloadRequestStartSignal _downloadRequestStartSignal = _DownloadRequestStartSignal(identify, netWorkContainer, netWorkContainer.savePath,
        isDevelop: _config!.isDevelop,
        errorDeal: _config?.errorDeal ?? ErrorDealDefault()
    );
    send.add(_downloadRequestStartSignal);
    _longRunningSlave[identify] = netWorkContainer.identify;
  }
  /// 普通请求
  void _request(StreamController send, int identify, HttpContainer netWorkContainer){
    _RequestStartSignal _requestStartSignal = _RequestStartSignal(identify, netWorkContainer,
        isDevelop: _config!.isDevelop,
        errorDeal: _config?.errorDeal ?? ErrorDealDefault()
    );
    send.add(_requestStartSignal);
  }

  /// 初始化锁
  Completer<Null> _initAssignedLock() {
    Completer<Null> completer = Completer<Null>();
    _assignedTaskLock = completer.future;
    return completer;
  }

  /// 解锁
  void _unLock(Completer<Null> completer) {
    completer.complete();
  }

  /// 等待解锁
  Future<void> _waitingLock() async {
    if (_assignedTaskLock != null) {
      await _assignedTaskLock;
      return null;
    } else
      return null;
  }
}

class _TaskNotification<T> {
  /// 发送器
  final StreamController<T> send = StreamController.broadcast();
  /// 接受
  Stream get receive => send.stream;
  /// 订阅
  late StreamSubscription _scription;
  /// 监听
  void listen(void Function(dynamic) data){
    _scription = receive.listen(data);
  }

  /// 销毁
  void dispose(){
    _scription.cancel();
    send.close();
  }
}

/// 请求标识
class _SampleContainer {
  /// 标识
  final int identify;

  /// 归属
  final int? belongTo;

  _SampleContainer(this.identify, this.belongTo);
}

/// 线程查找
class _CanWork {
  /// 线程
  final int? slaveIdentify;

  /// 是否能工作
  final bool canWork;

  _CanWork(this.canWork,{this.slaveIdentify});
}

/// 奴隶 工作者
class _Slave {
  /// 初始化
  _Slave(StreamController send,
      {int timeLimit = 600, bool isOriginal = false})
      : this._send = send,
        this._timeLimit = timeLimit,
        this._isOriginal = isOriginal {
    startLock();
    _init();
  }

  /// 初始化线程
  _init() async {
    _slaveEnterPoint(_SlaveIdentify(this.identify, _send));
    if (!_isOriginal) {
      _timer = Timer.periodic(Duration(seconds: 1), _timerFunc);
    }
  }

  /// 最大时限
  int _timeLimit;

  /// 原始线程
  bool _isOriginal;

  /// 闲置时间
  int _time = 0;
  Timer? _timer;

  StreamController _send;

  Completer<Null>? _lockCompleter;

  /// 线程锁
  Future<Null>? _lock;

  /// 能否增加新任务
  bool get canWork => _lock == null;

  /// 位置
  int get identify => this.hashCode;
  final _TaskNotification _task = _TaskNotification();

  /// 定时工作
  void _timerFunc(_) {
    /// 如果 正在工作 则不允许关闭
    _time++;

    /// 如果 到了最大时限 则关闭
    if (_time == _timeLimit) {
      _send.add(_SlaveClose(identify));
      Future.delayed(Duration(milliseconds: 300)).then((_) {
        _kill();
      });
    }
  }

  /// 加锁
  void startLock() {
    print("slave start lock -------");
    _time = 0;
    _lockCompleter = Completer<Null>();
    _lock = _lockCompleter!.future
      ..then((value) {
        _lock = null;
      });
  }

  /// 解锁
  void endLock() {
    print(
        "slave end lock ---the _lockCompleter == null is ${_lockCompleter ==
            null}----");
    _time = 0;
    if (_lockCompleter == null) {
      _lock = null;
    }
    _lockCompleter?.complete();
    _lockCompleter = null;
  }

  /// 关闭 停止工作
  void _kill() {
    _task.dispose();
    _timer!.cancel();
    _timer = null;
  }

  /// 线程入口
  void _slaveEnterPoint(_SlaveIdentify slaveIdentify) {

    /// 请求工具
    late _WrapDio _wrapDio;

    /// 取消请求
    late CancelToken _cancelToken;

    ErrorReason catchError(dynamic e, msg, DateTime requestStart) {
      Alog.e(
          "request: ${msg.container.url} --- run at slave: ${slaveIdentify
              .identify} spend ${DateTime.now().difference(requestStart)}");
      String u = "";
      if (msg.isDevelop)
        u = msg.container.url.replaceAll(msg.container.baseAddress, "");
      return msg.errorDeal.dealWithError(e, u);
    }

    /// 开始接收消息
    _task.listen((msg) {
      /// 开始初始化
      if (msg is _InitDio) {
        _wrapDio = _WrapDio(connectTimeOut: msg.connectTimeOut, timeOut: msg.timeOut,
            isDevelop: msg.isDevelop, proxyUrl: msg.proxyUrl, interceptor: msg.interceptor,
        enableRedirect: msg.enableRedirect, status: msg.status);
        _cancelToken = CancelToken();
        slaveIdentify.send.add(_SlaveInitComplete(msg.identify, _task.send));
      }

      /// 请求
      if (msg is _RequestStartSignal) {
        DateTime requestStart = DateTime.now();
        HttpContainer container = msg.container;
        if (container.isFile) {
          if (container.body is String)
            container.body = File(container.body).openRead();
          else if (container.body is List<int>)
            container.body = MultipartFile.fromBytes(container.body).finalize();
        }
        print(
            "request: ${(container.baseAddress ?? "") +
                container.url} --- run at slave: ${slaveIdentify
                .identify} ");
        _wrapDio.request(container, _cancelToken).then((result) {
          print(
              "request: ${container.url} --- run at slave: ${slaveIdentify
                  .identify} spend ${DateTime.now().difference(requestStart)}");
          slaveIdentify.send.add(_RequestEndSignal(
              msg.identify, container.identify, _task.send,
              data: result.data, statusCode: result.code ?? -1));
        }).catchError((e) {
          var err = catchError(e, msg, requestStart);
          slaveIdentify.send.add(_RequestEndSignal(
              msg.identify, container.identify, _task.send,
              error: err.err, isSuccess: false, statusCode: err.code));
        });
      }

      if (msg is _DownloadRequestStartSignal) {
        DateTime requestStart = DateTime.now();
        _wrapDio.download(msg.container, msg.savePath ,_cancelToken, (count, amount) {
          slaveIdentify.send.add(_DownloadProcessSignal(msg.identify, msg.container.identify, count: count, amount: amount));
        }).then((result) {
          print(
              "request: ${msg.container.url} --- run at slave: ${slaveIdentify
                  .identify} spend ${DateTime.now().difference(requestStart)}");
          slaveIdentify.send.add(_DownloadRequestEndSignal(
              msg.identify, msg.container.identify, _task.send,
              headers: result.headers, data: msg.savePath, statusCode: result.code ?? -1));
        }).catchError((e) {
          var err = catchError(e, msg, requestStart);
          slaveIdentify.send.add(_DownloadRequestEndSignal(
              msg.identify, msg.container.identify, _task.send,
              error: err.err, isSuccess: false, statusCode: err.code));
        });
      }

      if (msg is _UploadRequestStartSignal) {
        DateTime requestStart = DateTime.now();
        HttpContainer container = msg.container;
        if (container.isFile) {
          if (container.body is String)
            container.body = File(container.body).openRead();
          else if (container.body is List<int>)
            container.body = MultipartFile.fromBytes(container.body).finalize();
        }
        _wrapDio.upload(container, _cancelToken, (count, total) {
          print("upload request the count is $count, the total is $total ---- ");
          slaveIdentify.send.add(_UploadProcessSignal(msg.identify, msg.container.identify, count: count, amount: total));
        }).then((result) {
          print(
              "request: ${msg.container.url} --- run at slave: ${slaveIdentify
                  .identify} spend ${DateTime.now().difference(requestStart)}");
          slaveIdentify.send.add(_UploadRequestEndSignal(
              msg.identify, msg.container.identify, _task.send,
              data: result.data, statusCode: result.code ?? -1));
        }).catchError((e) {
          var err = catchError(e, msg, requestStart);
          slaveIdentify.send.add(_UploadRequestEndSignal(
              msg.identify, msg.container.identify, _task.send,
              error: err.err, isSuccess: false, statusCode: err.code));
        });
      }

      /// 用户取消请求
      if (msg is _SlaveCancel) {
        _cancelToken.cancel(msg.msg);
        _cancelToken = CancelToken();
      }

      /// dio 更新配置
      if (msg is _ConfigUpdateSignal) {
        _wrapDio.updateConfig(
            interceptor: msg.interceptor,
          connectTimeOut: msg.connectTimeOut!,
          timeOut: msg.timeOut!,
          status: msg.status,
          proxyUrl: msg.proxyUrl,
          isDevelop: msg.isDevelop
        );
        slaveIdentify.send.add(_ConfigUpdateComplete(msg.identify, send: _task.send));
      }
    });

    /// 开始初始化
    slaveIdentify.send.add(_SlaveSetUp(slaveIdentify.identify, _task.send));
  }
}

/// slave 标识符
class _SlaveIdentify {
  final StreamController send;
  final int identify;

  _SlaveIdentify(this.identify, this.send);
}

abstract class _SlaveSignalBase {
  /// 线程标识符
  final int identify;

  _SlaveSignalBase(this.identify);
}

/// 线程关闭
class _SlaveClose extends _SlaveSignalBase {
  _SlaveClose(int identify) : super(identify);
}

/// 线程初始化完成
class _SlaveInitComplete extends _SlaveSignalBase {
  /// 发送端口
  final StreamController send;

  _SlaveInitComplete(int identify, this.send) : super(identify);
}

/// 线程 启动
class _SlaveSetUp extends _SlaveSignalBase {
  /// 发送端口
  final StreamController send;

  _SlaveSetUp(int slaveIdentify, this.send) : super(slaveIdentify);
}

/// 取消请求
class _SlaveCancel {
  final String msg;
  _SlaveCancel({this.msg: "用户已取消请求"});
}

/// dio 初始化
class _InitDio extends _SlaveSignalBase {
  /// 请求超时
  final int timeOut;

  /// 连接超时
  final int connectTimeOut;

  /// 是否是开发环境
  final bool? isDevelop;

  /// 拦截地址
  final String? proxyUrl;

  final Interceptor? interceptor;

  /// 是否允许重定向
  final bool? enableRedirect;
  final List<int> status;

  _InitDio(int slaveIdentify, {required this.timeOut, required this.connectTimeOut, this.enableRedirect,
    this.isDevelop, this.proxyUrl, this.interceptor, required this.status})
      : super(slaveIdentify);
}

/// 开始请求
class _RequestStartSignal extends _SlaveSignalBase {
  final HttpContainer container;
  final bool? isDevelop;
  final ErrorDeal errorDeal;
  _RequestStartSignal(int identify, this.container, {this.isDevelop, required this.errorDeal}) : super(identify);
}

/// 开始下载
class _DownloadRequestStartSignal extends _SlaveSignalBase {
  final HttpContainer container;
  final bool? isDevelop;
  final String? savePath;
  final ErrorDeal errorDeal;

  _DownloadRequestStartSignal(int identify, this.container, this.savePath, {this.isDevelop, required this.errorDeal}) : super(identify);
}

/// 下载进度发生改变
class _DownloadProcessSignal extends _SlaveSignalBase {
  final int count;
  final int amount;
  final int requestIdentify;
  _DownloadProcessSignal(int identify, this.requestIdentify, {required this.count, required this.amount}): super(identify);
}

/// 下载结束
class _DownloadRequestEndSignal extends _SlaveSignalBase{
  /// 请求结果
  final dynamic data;

  /// 请求出现异常
  final dynamic error;

  /// 请求标识符
  final int requestIdentify;

  /// 发送端口
  final StreamController send;

  /// 是否成功
  final bool isSuccess;

  /// 网络请求状态码
  final int statusCode;

  /// 返回下载header
  final Headers? headers;
  _DownloadRequestEndSignal(int identify, this.requestIdentify, this.send,
      {this.data, this.error, this.isSuccess = true, required this.statusCode, this.headers})
      : super(identify);
}

/// 开始上传
class _UploadRequestStartSignal extends _SlaveSignalBase {
  final HttpContainer container;
  final bool? isDevelop;
  final ErrorDeal errorDeal;
  _UploadRequestStartSignal(int identify, this.container, {this.isDevelop, required this.errorDeal}) : super(identify);
}

/// 上传发生变化
class _UploadProcessSignal extends _SlaveSignalBase {
  final int count;
  final int amount;
  final int requestIdentify;
  _UploadProcessSignal(int identify, this.requestIdentify, {required this.count, required this.amount}): super(identify);
}

/// 下载结束
class _UploadRequestEndSignal extends _SlaveSignalBase{
  /// 请求结果
  final dynamic data;

  /// 请求出现异常
  final dynamic error;

  /// 请求标识符
  final int requestIdentify;

  /// 发送端口
  final StreamController send;

  /// 是否成功
  final bool isSuccess;

  /// 网络请求状态码
  final int statusCode;
  _UploadRequestEndSignal(int identify, this.requestIdentify, this.send,
      {this.data, this.error, this.isSuccess = true, required this.statusCode})
      : super(identify);
}

/// 请求结束
class _RequestEndSignal extends _SlaveSignalBase {
  /// 请求结果
  final dynamic data;

  /// 请求出现异常
  final dynamic error;

  /// 请求标识符
  final int requestIdentify;

  /// 发送端口
  final StreamController send;

  /// 是否成功
  final bool isSuccess;

  /// 网络请求状态码
  final int statusCode;

  _RequestEndSignal(int identify, this.requestIdentify, this.send,
      {this.data, this.error, this.isSuccess = true, required this.statusCode})
      : super(identify);
}

class _ConfigUpdateSignal extends _SlaveSignalBase{
  /// 请求超时
  final int? timeOut;

  /// 连接超时
  final int? connectTimeOut;

  /// 是否是开发环境
  final bool? isDevelop;

  /// 拦截地址
  final String? proxyUrl;

  final Interceptor? interceptor;

  final List<int> status;
  _ConfigUpdateSignal(int identify, {this.proxyUrl, this.interceptor,
    this.connectTimeOut, this.isDevelop, this.timeOut, required this.status}): super(identify);
}

/// 更新配置完成
class _ConfigUpdateComplete extends _SlaveSignalBase{
  final StreamController send;
  _ConfigUpdateComplete(int identify, {required this.send}): super(identify);
}

/// dio公用配置
class _WrapDio {
  /// 请求超时
  final int? timeOut;

  /// 连接超时
  final int? connectTimeOut;

  List<int> status = [];

  late Dio _dio;

  int? times;

  _WrapDio({this.connectTimeOut, this.timeOut, bool? isDevelop, String? proxyUrl,
    Interceptor? interceptor, bool? enableRedirect,
    required List<int> status
  }) {
    this.status = status;
    _dio = Dio(BaseOptions(
      followRedirects: enableRedirect,
      connectTimeout: connectTimeOut,
      receiveTimeout: timeOut,
      validateStatus: (status) => (status ?? 600) < 500
    ));

    // (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
    //     (client) {
    //   /// 设置忽略证书
    //   client.badCertificateCallback =
    //       (X509Certificate cert, String host, int port) {
    //     return true;
    //   };
    // };

    // /// proxyUrl 不为空 则设置拦截地址
    // if (proxyUrl != null && proxyUrl.isNotEmpty) {
    //   (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =  (httpClient) {
    //     httpClient.findProxy = (url) {
    //       final proxy = proxyUrl;//'192.168.1.61:8888';
    //       print('通过代理 $proxy 访问 $url');
    //       return 'PROXY $proxy';
    //     };
    //     httpClient.badCertificateCallback = (cert, host, port) {
    //       print('证书 $cert , 地址:$host:$port');
    //       return true;
    //     };
    //   };
    // }

    if (interceptor != null) {
      _dio.interceptors.add(interceptor);
    }

    LogInterceptor logInterceptor = LogInterceptor(
      requestBody: true,
      requestHeader: true,
      responseBody: true,
      responseHeader: true,
    );

    /// 加入日志打印
    _dio.interceptors.add(logInterceptor);
  }

  /// 更新配置
  void updateConfig({required int connectTimeOut, required int timeOut, bool? isDevelop,
    String? proxyUrl, Interceptor? interceptor, required List<int> status}){
    this.status = status;
    /// 重新配置超时时间
    _dio.options..connectTimeout = connectTimeOut
      ..receiveTimeout = timeOut;
    /// 移除cookie manager
    _dio.interceptors.removeWhere((element) => element == interceptor);
    /// proxyUrl 不为空 则设置拦截地址
    // if (proxyUrl != null && proxyUrl.isNotEmpty) {
    //   (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =  (httpClient) {
    //     httpClient.findProxy = (url) {
    //       final proxy = proxyUrl;//'192.168.1.61:8888';
    //       print('通过代理 $proxy 访问 $url');
    //       return 'PROXY $proxy';
    //     };
    //     httpClient.badCertificateCallback = (cert, host, port) {
    //       print('证书 $cert , 地址:$host:$port');
    //       return true;
    //     };
    //   };
    // }
    /// 如果有cookie 添加cookie manager
    if (interceptor != null) {
      _dio.interceptors.add(interceptor);
    }
  }

  /// 开始请求
  Future<_DioResultContainer> request(HttpContainer container,
      CancelToken cancelToken) async {
    Options options = Options(
        headers: container.header,
        method: container.method,
        // followRedirects: false,
        // maxRedirects: 0,
        // validateStatus: (s) => s != null && s < 500,
        contentType: container.header == null ? null : container.header!["content-type"]);
    if (this.times == null) {
      this.times = container.retryTimes;
    }

    Response response;
    if(container.needJoinQueryParameterBySelf) {
      String uri = container.customUrl ?? ((container.baseAddress ?? "") + container.url);
      container.customUrl = "$uri?${container.queryParameters.keys.toList()
          .map((e) => "$e=${container.queryParameters[e]}").toList().join("&")}";
      container.queryParameters = {};
    }

    try{
      response = await _dio.request(
          container.customUrl ?? ((container.baseAddress ?? "") + container.url),
          data: container.body,
          options: options,
          cancelToken: cancelToken,
          queryParameters: container.queryParameters);
    }catch(err) {
      // print("the error is $err");
      if (this.times != null && this.times! > 0) {
        if (err is DioError && err.type == DioErrorType.cancel) {
          this.times = null;
          throw err;
        }else {
          this.times = this.times! - 1;
          return request(container, cancelToken);
        }
      }
      this.times = null;
      throw err;
    }
    _DioResultContainer result = _DioResultContainer(data: response.data, code: response.statusCode);
    if (result.code != 200 && !status.contains(result.code) &&
        this.times != null && this.times! > 0) {
      this.times = this.times! - 1;
      return request(container, cancelToken);
    }
    this.times = null;
    return Future.value(result);
  }

  /// 下载文件
  Future<_DioResultContainer> download(HttpContainer container, String? savePath,
      CancelToken cancelToken, void Function(int, int) process) async{
    Options options = Options(
        headers: container.header,
        method: container.method,
        receiveTimeout: 0,
        contentType: container.header == null ? null : container.header!["content-type"]);
    if (this.times == null) {
      this.times = container.retryTimes;
    }

    Response response;
    var interceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          options.onReceiveProgress = (count, total) {
            process(count, total);
          };
          handler.next(options);
        }
    );
    _dio.interceptors.add(interceptor);
    try{
      response = await _dio.download(container.customUrl ?? ((container.baseAddress ?? "") + container.url), savePath,
          data: container.body, options: options, cancelToken: cancelToken, queryParameters: container.queryParameters,
          onReceiveProgress: (count, amount) {
            process(count, amount);
          }, deleteOnError: true);
    }catch(err) {
      if (this.times != null && this.times! > 0) {
        if (err is DioError && err.type == DioErrorType.cancel) {
          _dio.interceptors.remove(interceptor);
          this.times = null;
          throw err;
        }else {
          this.times = this.times! - 1;
          return download(container, savePath, cancelToken, process);
        }
      }
      _dio.interceptors.remove(interceptor);
      this.times = null;
      throw err;
    }
    _DioResultContainer result = _DioResultContainer(data: response.data,
        code: response.statusCode, headers: response.headers);
    _dio.interceptors.remove(interceptor);
    if (result.code != 200 && !status.contains(result.code) &&
        this.times != null && this.times! > 0) {
      this.times = this.times! - 1;
      return download(container, savePath, cancelToken, process);
    }
    this.times = null;
    return Future.value(result);
  }

  /// 上传文件
  Future<_DioResultContainer> upload(HttpContainer container, CancelToken cancelToken, void Function(int ,int) process) async{
    Options options = Options(
        headers: container.header,
        method: container.method,
        contentType: container.header == null ? null : container.header!["content-type"]);

    if (this.times == null) {
      this.times = container.retryTimes;
    }

    Response response;
    var interceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          options.onSendProgress = (count, total) {
            process(count, total);
          };
          handler.next(options);
        }
    );
    _dio.interceptors.add(interceptor);

    if (container.method == POST) {
      return request(container, cancelToken);
    }

    try {
      response = await _dio.put(container.customUrl ?? ((container.baseAddress ?? "") + container.url),
          data: container.body, options: options, cancelToken: cancelToken,
          queryParameters: container.queryParameters, onSendProgress: (count, total) {
            process(count, total);
          });
    }catch(err) {
      if (this.times != null && this.times! > 0) {
        if (err is DioError && err.type == DioErrorType.cancel) {
          _dio.interceptors.remove(interceptor);
          this.times = null;
          throw err;
        }else {
          this.times = this.times! - 1;
          return upload(container, cancelToken, process);
        }
      }
      _dio.interceptors.remove(interceptor);
      this.times = null;
      throw err;
    }
    _DioResultContainer result = _DioResultContainer(data: response.data, code: response.statusCode);
    _dio.interceptors.remove(interceptor);
    if (result.code != 200 && !status.contains(result.code) &&
        this.times != null && this.times! > 0) {
      this.times = this.times! - 1;
      return upload(container, cancelToken, process);
    }
    this.times = null;
    return Future.value(result);
  }
}

/// dio 请求返回
class _DioResultContainer {
  /// 状态码
  final int? code;

  /// 返回的数据
  final dynamic data;

  final Headers? headers;
  _DioResultContainer({this.data, this.code, this.headers});
}
