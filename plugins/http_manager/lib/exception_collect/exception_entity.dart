/*
 *  Copyright (C), 2015-2020 , schw
 *  FileName: exception_entity
 *  Author: Tonight丶相拥
 *  Date: 2020/11/25
 *  Description: 
 **/

class ExceptionEntity {
  ExceptionEntity({this.key, this.value, this.exceptionTime, this.exceptionReason, this.operateTime});
  /// 数据源
  final Map<String, dynamic>? value;
  /// 请求key
  final String? key;
  /// 异常时间
  final DateTime? exceptionTime;
  /// 异常原因
  final String? exceptionReason;
  /// 操作时间
  final DateTime? operateTime;
  /// 利用json 初始化
  factory ExceptionEntity.fromJson(Map<String, dynamic> json){
    String key = json["key"];
    Map<String, dynamic> value = json["value"];
    String exceptionTime = json["exceptionTime"];
    String exceptionReason = json["exceptionReason"];
    DateTime time;
    try {
      time = DateTime.parse(exceptionTime);
    }catch(_) {
      time = DateTime.now();
    }
    String operateTime = json["operateTime"];
    DateTime time1;
    try {
      time1 = DateTime.parse(operateTime);
    }catch(_) {
      time1 = DateTime.now();
    }
    return ExceptionEntity(key: key, value: value, exceptionTime: time, exceptionReason: exceptionReason, operateTime: time1);
  }

  /// 转化成json
  Map<String, dynamic> toJson(){
    Map<String, dynamic> dic = {};
    dic["key"] = this.key;
    dic["value"] = this.value;
    dic["exceptionTime"] = this.exceptionTime?.toIso8601String();
    dic["exceptionReason"] = this.exceptionReason;
    return dic;
  }
}