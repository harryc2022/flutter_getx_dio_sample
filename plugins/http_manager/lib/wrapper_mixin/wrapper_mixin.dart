/*
 *  Copyright (C), 2015-2021
 *  FileName: wrapper_mixin
 *  Author: Tonight丶相拥
 *  Date: 2021/4/23
 *  Description: 
 **/


import 'package:httpplugin/http_manager/http_manager.dart';

mixin WrapperMixin {
  /// 请求状态码
  late var code;

  /// 是否请求成功
  bool get isSuccess;

  /// 消息
  late String msg;

  /// 数据
  dynamic object;

  void fromJson(dynamic value){
  }
}