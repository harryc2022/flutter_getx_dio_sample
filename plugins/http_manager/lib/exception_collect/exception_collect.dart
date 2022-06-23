/*
 *  Copyright (C), 2015-2020 , schw
 *  FileName: exception_collect
 *  Author: Tonight丶相拥
 *  Date: 2020/11/25
 *  Description: 
 **/

import 'package:flutter/material.dart' show ChangeNotifier;

abstract class ExceptionCollectAbstract extends ChangeNotifier{
  /// 添加异常
  void addException(Map<String, dynamic> exception);

  /// 操作日志
  void addOperation(Map<String, dynamic> exception);
}