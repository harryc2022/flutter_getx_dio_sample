import '../refresh_unit/token_refresh_unit.dart';

/// token 数据容器
class ClientDataContainer with ClientData {
  /// 超期时间
  DateTime? expireInTime;

  /// 数据请求口令
  final String? accessToken;

  /// 刷新口令
  final String? refreshToken;

  /// 可用服务
  final List<String>? scopes;

  /// token 类型
  final String? tokenType;

  final int? expireIn;

  /// 是否超期
  bool get isExpire {
    return DateTime.now().isAfter(expireInTime ?? DateTime.now().subtract(Duration(seconds: 1)));
  }

  /// 初始化
  ClientDataContainer(
      {this.accessToken,
      this.refreshToken,
      this.scopes,
      DateTime? time,
      this.tokenType, this.expireIn})
      : expireInTime = time;

  /// 工厂
  factory ClientDataContainer.fromJson(Map<String, dynamic> json, [RefreshUnit? _n]) {
    String token = json["access_token"];
    String refreshToken = json["refresh_token"];
    String tokenType = json["token_type"];
    String scopeJson = json["scope"];
    int expireIn = json["expires_in"];
    String expireInTime = json["expires_in_time"] ?? "";
    List<String> scope = scopeJson == null || scopeJson.isEmpty ? [] : scopeJson.split(" ");
    DateTime? expireTime;
    if (expireInTime != null && expireInTime.isNotEmpty) {
      try{
        expireTime = DateTime.parse(expireInTime);
      }catch(_){}
    }
    Duration duration;
    switch(_n ?? RefreshUnit.second){
      case RefreshUnit.day:
        duration = Duration(days: expireIn);
        break;
      case RefreshUnit.hour:
        duration = Duration(hours: expireIn);
        break;
      case RefreshUnit.minute:
        duration = Duration(minutes: expireIn);
        break;
      case RefreshUnit.millisecond:
        duration = Duration(milliseconds: expireIn);
        break;
      case RefreshUnit.microsecond:
        duration = Duration(microseconds: expireIn);
        break;
      default:
        duration = Duration(seconds: expireIn);
        break;
    }
    return ClientDataContainer(
        tokenType: tokenType,
        accessToken: token,
        refreshToken: refreshToken,
        time: expireTime ?? DateTime.now().add(duration),
        scopes: scope, expireIn: expireIn);
  }
}

abstract class ClientData {
  /// 超期时间
  DateTime? expireInTime;

  /// 数据请求口令
  final String? accessToken = "";

  /// 刷新口令
  final String? refreshToken = "";

  /// 可用服务
  final List<String>? scopes = [];

  /// token 类型
  final String? tokenType = "";

  final int? expireIn = 0;

  /// 是否超期
  bool get isExpire {
    return DateTime.now().isAfter(expireInTime ?? DateTime.now());
  }

  /// 判断client 是否为空
  bool get isLegal {
    return accessToken != null &&
        accessToken!.isNotEmpty &&
        refreshToken != null &&
        refreshToken!.isNotEmpty;
  }

  Map<String, dynamic> toJson(){
    Map<String, dynamic> json = {};
    json["access_token"] = accessToken;
    json["refresh_token"] = refreshToken;
    json["token_type"] = tokenType;
    json["scope"] = (scopes ?? []).join(" ");
    json["expires_in"] = expireIn;
    json["expires_in_time"] = expireInTime?.toIso8601String() ?? "";
    return json;
  }
}
