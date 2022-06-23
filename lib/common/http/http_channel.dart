/*
 *  Copyright (C), 2015-2021
 *  FileName: http_channel
 *  Author: Tonight丶相拥
 *  Date: 2021/3/11
 *  Description: 
 **/

library httpplugin;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
// import 'dart:isolate';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:httpplugin/httpplugin.dart';
import 'package:package_info/package_info.dart';
import 'package:uuid/uuid.dart';

import '../i18n/i18n.dart';
import '../utils/crypto/crypto.dart';
import 'containers.dart';

part 'http_channel_extension.dart';
part 'wrapper.dart';
part 'http_channel_mixin.dart';
part 'paging_mixin.dart';

typedef Failure = void Function(String);
typedef Success = void Function();

/// 请求管道
class HttpChannel with HttpChannelMixin {
  /// 实例
  static HttpChannel? _channel;

  /// 获取实例
  static HttpChannel get channel => _getInstance();

  /// 禁止外部初始化
  HttpChannel._();

  /// 启动
  static _getInstance() {
    if (_channel == null) {
      _channel = HttpChannel._();
    }
    return _channel;
  }

  /// 获取Ip
  String get ip => HttpMidBuffer.buffer.ip;

  /// 获取 端口
  String get port => HttpMidBuffer.buffer.port;

  /// 获取 token
  String get accessToken => HttpMidBuffer.buffer.accessToken;

  /// 刷新token
  String get refreshToken => HttpMidBuffer.buffer.refreshToken;

  /// 作用域
  List<String> get scopes => HttpMidBuffer.buffer.scopes;

  /// 超时时间
  DateTime get expireDateTime => HttpMidBuffer.buffer.expireDateTime;

  /// 启动
  Future<void> setUpChannel(
      {HttpConfig config = const HttpConfig(),
      bool connectivity = false,
      void Function()? connectivityChange,
      CacheBase? cache,
      ClientData? clientData,
      EventNotifyClass? eventListener,
      ExceptionCollectAbstract? exceptionCollect}) async {
    /// 启动
    await HttpMidBuffer.setUpMidBuffer(
        config: config,
        connectivity: connectivity,
        connectivityChange: connectivityChange,
        cache: cache,
        exceptionCollect: exceptionCollect,
        clientData: clientData,
        eventListener: eventListener);
    return null;
  }

  /// 添加任务(挂载)
  void addTickContainer(HttpTickContainer Function() container, String key) {
    HttpMidBuffer.buffer.addTickContainer(container, key);
  }

  /// 启动task mount
  void setUpTaskMount(Map<String, HttpTickContainer Function()> map) {
    HttpMidBuffer.buffer.setUpTaskMount(map);
  }

  /// 添加任务
  void addTickContainers(Map<String, HttpTickContainer Function()> ticks) {
    HttpMidBuffer.buffer.addTickContainers(ticks);
  }

  /// 更新设置
  void updateMidBuffer({required HttpConfig config}) {
    HttpMidBuffer.buffer.updateMidBuffer(config: config);
  }

  /// 清理数据
  void cleanClientData() {
    // HttpMidBuffer.buffer.cleanClientData();
  }

  // void setUp1({HttpConfig config = const HttpConfig(),
  //   bool connectivity = false,
  //   void Function()? connectivityChange,
  //   CacheBase? cache,
  //   ClientData? clientData, EventNotifyClass? eventListener,
  //   ExceptionCollectAbstract? exceptionCollect}) async{
  //   ReceivePort receivePort = ReceivePort();
  //   await Isolate.spawn<SettingConfig>(_enterPoint,
  //     SettingConfig(
  //       config: config,
  //       connectivity: connectivity,
  //       connectivityChange: connectivityChange,
  //       cache: cache,
  //       clientData: clientData,
  //       eventListener: eventListener,
  //       exceptionCollect: exceptionCollect
  //     )..port = receivePort);
  //   receivePort.listen((message) {
  //
  //   });
  // }
  //
  // static _enterPoint(SettingConfig settingConfig){
  //   ReceivePort port = ReceivePort();
  //   var _ = HttpMidBuffer.buffer;
  //   port.listen((message) {
  //     settingConfig.port.sendPort.send(port);
  //   });
  // }
}

// class SettingConfig {
//   SettingConfig({required this.config,
//     required this.connectivity,
//     this.connectivityChange,
//     this.cache,
//     this.clientData,
//     this.eventListener,
//     this.exceptionCollect
//   });
//   late ReceivePort port;
//   HttpConfig config;
//   bool connectivity;
//   void Function()? connectivityChange;
//   CacheBase? cache;
//   ClientData? clientData;
//   EventNotifyClass? eventListener;
//   ExceptionCollectAbstract? exceptionCollect;
// }


// /// 更新认证信息
// bool updateClientDataWith(ClientData clientData) {
//   return HttpMidBuffer.buffer.updateClientDataWith(clientData);
// }

// /// 刷新token
// Future<HttpResultContainer> refresh() {
//   return HttpMidBuffer.buffer.refresh();
// }

// /// 取消计时
// void cancelTimer(){
//   HttpMidBuffer.buffer.cancelTimer();
// }

// /// 登录
// Future<HttpResultContainer> logIn(String name, String passWord) {
//   return HttpMidBuffer.buffer.initializeOauth({
//     HttpPluginKey.BODY: {"username": name, "password": passWord}
//   });
// }