/*
 *  Copyright (C), 2015-2021
 *  FileName: containers
 *  Author: Tonight丶相拥
 *  Date: 2021/3/11
 *  Description: 
 **/

import 'package:httpplugin/httpplugin.dart' show HttpTickContainer;
import 'package:url_launcher/link.dart';
import 'request.dart';

class AppRequest {
  // 登录
  static const String logIn = "index/login";

  /// 获取验证码
  static const String smsSend = "captcha/sms/send";

  /// 所有请求
  static Map<String, HttpTickContainer Function()> request = {
    logIn: () => Login(),
    smsSend: () => SmsSend(),
  };


}
