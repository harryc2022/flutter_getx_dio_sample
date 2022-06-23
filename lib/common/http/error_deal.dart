/*
 *  Copyright (C), 2015-2022
 *  FileName: error_deal
 *  Author: Tonight丶相拥
 *  Date: 2022/1/18
 *  Description: 
 **/
import 'dart:convert';

import 'package:httpplugin/response_deal/error_deal.dart';

import '../i18n/i18n.dart';
import '../widget/toast.dart';
class CustomErrorDeal extends ErrorDeal with Toast  {
  Map<String, _Reason> _reason = {};
  _Reason get _onReason {
    String key = "";
    if (AppInternational.current is $en) {
      key = "en";
      if (!_reason.containsKey(key)) {
        _reason[key] = _Reason$EN();
      }
    }else {
      key = "zh";
      if (!_reason.containsKey(key)) {
        _reason[key] = _Reason$ZH();
      }
    }
    return _reason[key]!;
  }

  @override
  // TODO: implement onDioCancel
  String get onDioCancel => _onReason.onDioCancel;

  @override
  // TODO: implement onDioConnectTimeOut
  String get onDioConnectTimeOut => _onReason.onDioConnectTimeOut;

  @override
  String onDioOther(error) => _onReason.onDioOther(error);

  @override
  // TODO: implement onDioReceiveTimeOut
  String get onDioReceiveTimeOut => _onReason.onDioReceiveTimeOut;

  @override
  String onDioResponse(int code) => _onReason.onDioResponse(code);

  @override
  // TODO: implement onDioSendTimeOut
  String get onDioSendTimeOut => _onReason.onDioSendTimeOut;

  @override
  // TODO: implement onSocketException
  String get onSocketException => _onReason.onSocketException;

  @override
  // TODO: implement onUnknown
  String get onUnknown => _onReason.onUnknown;

  @override
  String dio400Deal(data) {
    // TODO: implement dio400Deal
    String err;
    try{
      err = jsonEncode(data);
    }catch(_) {
      err = data?.toString() ?? "";
    }
    return err;
  }

  @override
  void tokenError(String msg) {
    showToast(msg);
    Future.delayed(Duration(seconds: 0)).then((value) => {
      // (Get.find<MyMineSettingLogic>()).loginOut(NavKey.navKey.currentContext!)
    });
  }
}

abstract class _Reason {
  String get onDioCancel;
  String get onDioConnectTimeOut;
  String onDioOther(error);
  String get onDioReceiveTimeOut;
  String onDioResponse(int code);
  String get onDioSendTimeOut;
  String get onSocketException;
  String get onUnknown;
}

class _Reason$ZH extends _Reason {
  String get onDioCancel => "你已经取消请求";
  String get onDioConnectTimeOut => "连接超时";
  String get onDioSendTimeOut => "请求超时";
  String get onSocketException => "网络连接失败，请检查网络";
  String onDioOther(error) => "请求发生错误，请检查网络";
  String get onDioReceiveTimeOut => "接收超时";
  String onDioResponse(int code) => "服务器响应了，但状态不正确 $code";
  String get onUnknown => "未知错误";
}

class _Reason$EN extends _Reason {
  String get onDioCancel => "You Cancel Request";
  String get onDioConnectTimeOut => "Connect Time Out";
  String onDioOther(error) => "An error occurred in the request，please check the network";
  String get onDioReceiveTimeOut => "Receive Time Out";
  String onDioResponse(int code) => "The server responded with an incorrect status $code";
  String get onDioSendTimeOut => "Send Time Out";
  String get onSocketException => "Network connection failed, please check the network";
  String get onUnknown => "Unknown Error";
}