// 注册请求
class UserRegisterRequestEntity {
  String email;
  String password;

  UserRegisterRequestEntity({
    required this.email,
    required this.password,
  });

  factory UserRegisterRequestEntity.fromJson(Map<String, dynamic> json) =>
      UserRegisterRequestEntity(
        email: json["email"],
        password: json["password"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
      };
}
// "type": type,
// "account": account,
// "device": 1,
// "code": code,
// "codeId": codeId,
// 登录请求
class UserLoginRequestEntity {
  String type;
  String account;
  String codeId;
  String code;
  int device;

  UserLoginRequestEntity({
    required this.account,
    required this.code,
    required this.type,
    required this.codeId,
    this.device=1,
  });

  factory UserLoginRequestEntity.fromJson(Map<String, dynamic> json) =>
      UserLoginRequestEntity(
        account: json["account"],
        code: json["code"],
        type: json["type"],
        codeId: json["codeId"],
        device: json["device"],
      );

  Map<String, dynamic> toJson() => {
        "account": account,
        "code": code,
        "codeId": codeId,
        "type": type,
        "device": device,
      };
}

// 登录返回
class UserLoginResponseEntity {
  String? accessToken;
  String? displayName;
  List<String>? channels;

  UserLoginResponseEntity({
    this.accessToken,
    this.displayName,
    this.channels,
  });

  factory UserLoginResponseEntity.fromJson(Map<String, dynamic> json) =>
      UserLoginResponseEntity(
        accessToken: json["access_token"],
        displayName: json["display_name"],
        channels: List<String>.from(json["channels"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "access_token": accessToken,
        "display_name": displayName,
        "channels":
            channels == null ? [] : List<dynamic>.from(channels!.map((x) => x)),
      };
}
