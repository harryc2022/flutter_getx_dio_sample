/*
 *  Copyright (C), 2015-2021
 *  FileName: request
 *  Author: Tonight丶相拥
 *  Date: 2021/3/11
 *  Description: 
 **/

import 'package:httpplugin/http_container/http_container.dart';
import 'package:httpplugin/httpplugin.dart';

class Login extends HttpTickContainer {
  @override
  // TODO: implement url
  String get url => "/api/app/enter/login.no";
  // @override
  // // TODO: implement url
  // String get url => "/agora-0.0.1-SNAPSHOT/app/login";

  @override
  // TODO: implement method
  String get method => POST;
}

class SmsSend extends HttpTickContainer {
  @override
  // TODO: implement url
  String get url => "/api/app/captcha/sms/send";

  @override
  // TODO: implement method
  String get method => POST;
}
