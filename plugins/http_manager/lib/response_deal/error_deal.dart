/*
 *  Copyright (C), 2015-2022
 *  FileName: error_deal
 *  Author: Tonight丶相拥
 *  Date: 2022/1/18
 *  Description: 
 **/

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

/// 错误原因
class ErrorReason {
  final int code;
  final String err;
  ErrorReason(this.code, this.err);
}

abstract class ErrorDeal {
  const ErrorDeal();
  ErrorReason dealWithError(dynamic e, String u) {
    String err;
    int code = -1;
    if (e is SocketException) {
      code = e.osError?.errorCode ?? 0;
      err = onSocketException;
    } else if (e is DioError) {
      code = e.response?.statusCode ?? 1;
      if (e.type == DioErrorType.cancel) {
        err = onDioCancel;
        code = -2;
      } else if (e.type == DioErrorType.connectTimeout) {
        err = onDioConnectTimeOut;
      } else if (e.type == DioErrorType.sendTimeout) {
        err = onDioSendTimeOut;
      } else if (e.type == DioErrorType.receiveTimeout) {
        err = onDioReceiveTimeOut;
      } else if (e.type == DioErrorType.response) {
        if(code == 400 || code == 401)
          err = dio400Deal(e.response?.data);
        else
          err = onDioResponse(e.response?.statusCode ?? 0);
      } else {
        err = onDioOther(e);
      }
      if ((e.response?.statusCode ?? 0) != 400)
        err = err + u;
    } else {
      err = onUnknown + u;
    }
    return ErrorReason(code, err);
  }

  /// 网络连接失败，请检查网络
  String get onSocketException;
  /// 你已经取消请求
  String get onDioCancel;
  /// 连接超时
  String get onDioConnectTimeOut;
  /// 请求超时
  String get onDioSendTimeOut;
  /// 接收超时
  String get onDioReceiveTimeOut;
  /// "服务器响应了，但状态不正确 ${e.response?.statusCode}"
  String onDioResponse(int code);
  /// "其他错误：${e.error?.toString() ?? "未知"}"
  String onDioOther(DioError error);
  /// 未知错误
  String get onUnknown;
  /// dio 400 处理
  String dio400Deal(dynamic data);

  void tokenError(String msg);
}

class ErrorDealDefault extends ErrorDeal {

  const ErrorDealDefault();
  @override
  // TODO: implement onDioCancel
  String get onDioCancel => "你已经取消请求";

  @override
  // TODO: implement onDioConnectTimeOut
  String get onDioConnectTimeOut => "连接超时";

  @override
  String onDioOther(DioError error) => "其他错误：${error.error?.toString() ?? "未知"}";

  @override
  // TODO: implement onDioReceiveTimeOut
  String get onDioReceiveTimeOut => "接收超时";

  @override
  String onDioResponse(int code) => "服务器响应了，但状态不正确 $code";

  @override
  // TODO: implement onDioSendTimeOut
  String get onDioSendTimeOut => "请求超时";

  @override
  // TODO: implement onSocketException
  String get onSocketException => "网络连接失败，请检查网络";

  @override
  // TODO: implement onUnknown
  String get onUnknown => "未知错误";

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
    // TODO: implement tokenError
  }
}