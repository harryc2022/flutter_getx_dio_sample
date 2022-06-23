/*
 *  Copyright (C), 2015-2021
 *  FileName: http_channel_extension
 *  Author: Tonight丶相拥
 *  Date: 2021/3/11
 *  Description: 
 **/

part of httpplugin;

extension HttpChannelExtension on HttpChannel {
  /// 取消请求
  void cancelRequest(int token) {
    HttpMidBuffer.buffer.cancelRequestWidth(token);
  }

  /// 登录
  /// type：0-游客登录、1-账号登录
  Future<HttpResultContainer> logIn(String account, String code,String codeId,
      {String? type}) {
    return _onCommonRequest(
        AppRequest.logIn,
        {
          HttpPluginKey.BODY: {
            "type": type,
            "account": account,
            "device": 1,
            "code": code,
            "codeId": codeId,
          }
        },
        needToken: false);
  }


  /// 获取验证码
  Future<HttpResultContainer> smsSend({required String phone}) {
    return _onCommonRequest(AppRequest.smsSend, {
      HttpPluginKey.BODY: {"phone": phone}
    });
  }
}

// 分页数
const int _pageSize = 10;
