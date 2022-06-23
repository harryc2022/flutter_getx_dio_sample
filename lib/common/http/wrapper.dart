/*
 *  Copyright (C), 2015-2021
 *  FileName: wrapper
 *  Author: Tonight丶相拥
 *  Date: 2021/3/11
 *  Description: 
 **/

part of httpplugin;

class WrapperModel with WrapperMixin {
  WrapperModel({this.code: -1, this.msg: "", this.object});
  /// 返回状态码
  var code;

  /// 消息
  String msg;

  /// 数据
  dynamic object;

  /// 数据是否请求成功
  bool get isSuccess => code == 0;

  /// 解析
  factory WrapperModel.fromJson(dynamic value){
    Map<String, dynamic> json = {
      "msg": "$value"
    };
    if (value is Map) {
      json = Map.castFrom(value);
    }else if (value is String){
      try {
        json = jsonDecode(value);
      }catch(_) {}
    }
    var code = json["code"] ?? -1;
    String msg = (json["msg"] ?? "").toString();
    dynamic object = json["data"];
    return WrapperModel(
      code: code,
      msg: msg,
      object: object
    );
  }

  @override
  void fromJson(dynamic value) {
    // TODO: implement fromJson
    super.fromJson(value);
    Map<String, dynamic> json = {
      "msg": "$value"
    };
    if (value is Map) {
      json = Map.castFrom(value);
    }else if (value is String){
      try {
        json = jsonDecode(value);
      }catch(_) {}
    }
    var code = json["code"] ?? -1;
    String msg = (json["message"] ?? "").toString();
    dynamic object = json["data"];
    this.code = code;
    this.msg = msg;
    this.object = object;
  }
}


//{
//     "code": "200",
//     "message": "login successful",
//     "result": {
//         "expire": "2021-07-30T03:32:55.893",
//         "token": "230835e1f929896868e43a88d0a50798"
//     }
// }