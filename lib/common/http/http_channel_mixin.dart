/*
 *  Copyright (C), 2015-2021
 *  FileName: http_channel_mixin
 *  Author: Tonight丶相拥
 *  Date: 2021/7/26
 *  Description: 
 **/

part of httpplugin;

mixin HttpChannelMixin {
  static String _key = "*6n^GHkjGFVUYsdfcv";

  // String _key = "sds1LI2OW&E&%@kI&FCuy";
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  // Future<HttpResultContainer> _onCommonTokenRequest(String path,
  //     Map<String, dynamic> para, {bool needToken: true,
  //       void Function(int? token)? cancelToken}) async {
  //   return _onCommonRequest(AppRequest.userInfo, {
  //     HttpPluginKey.HEADER: {"token": AppManager
  //         .getInstance<AppUser>()
  //         .token!},
  //   });
  // }

  Future<HttpResultContainer> _onCommonRequest(String path,
      Map<String, dynamic> para, {bool needToken: true,
        void Function(int? token)? cancelToken}) async {
    String token = "";

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String udid = Uuid().v1().toString();
    int ts = DateTime
        .now()
        .toUtc()
        .millisecondsSinceEpoch;
    String uuid = UUID.random((ts / 1000).floor());

    String sTime = ts.toString();
    int time = int.parse(sTime.substring(sTime.length - 3, sTime.length));
    int hash = UUID.hash(uuid);
    int mode1 = (time + hash) % 5;

    String sha = Sha256(mode1)
        .convert(utf8.encode(token + _key + sTime + uuid + udid))
        .toString();
    int mode2 = (time * hash) % 5;
    sha = Sha256(mode2)
        .convert(utf8.encode(sha + _key + packageInfo.version + ts.toString()))
        .toString();

    String key1 = sha.substring(mode1, mode1 + 8) + sha.substring(32 - 8, 32);
    int offset = mode2 + 32;
    String key2 = sha.substring(offset, offset + 8) + sha.substring(64 - 8, 64);

    Map<String, dynamic> dev = {};
    dev["packageName"] = packageInfo.packageName;
    dev["buildNumber"] = packageInfo.buildNumber;
    if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      dev["model"] = iosDeviceInfo.model;
      dev["product"] = iosDeviceInfo.name;
      dev["isPhysicalDevice"] = iosDeviceInfo.isPhysicalDevice;
      dev["kid"] = iosDeviceInfo.identifierForVendor;
      var systemName = iosDeviceInfo.systemName;
      var systemVersion = iosDeviceInfo.systemVersion;
      dev["sdk"] = (systemName ?? "") + (systemVersion ?? "");
      dev["plat"] = "ios";
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      dev["model"] = androidDeviceInfo.model;
      dev["display"] = androidDeviceInfo.display;
      dev["tags"] = androidDeviceInfo.tags;
      dev["product"] = androidDeviceInfo.product;
      dev["isPhysicalDevice"] = androidDeviceInfo.isPhysicalDevice;
      dev["androidId"] = androidDeviceInfo.androidId;
      dev["sdk"] = androidDeviceInfo.version.release;
      dev["plat"] = "and";
    }
    // String body = jsonEncode({"dev": jsonEncode(dev), "data": jsonEncode(para[HttpPluginKey.BODY])});

    String body = jsonEncode(para[HttpPluginKey.BODY]);
    String _header = jsonEncode({
      'ts': ts.toString(),
      'uuid': uuid,
      'token': token,
      'ver': packageInfo.version,
      'udid': udid,
      'lan': AppInternational.current is $zh_CN ? "zh" : "en"
    });
    String _headstr = xxtea.encryptToString(_header,
        Uint8List.fromList(
            [12, 87, 86, 33, 0, 2, 45, 73, 24, 78, 121, 78, 60, 9, 87, 29]));
    String _body = xxtea.encryptToString(body, key1);
    // para[HttpPluginKey.BODY] =  _headstr + "#" + _body;
    para[HttpPluginKey.BODY] = body;
    para[HttpPluginKey.HEADER] = {"token": token};

    var resultContainer = await HttpMidBuffer.buffer.requestWithParameter(
        path, para,
        cancelToken: cancelToken);
    if (!resultContainer.isSuccess || resultContainer.data is Map
        || resultContainer.data is List) {
      return resultContainer;
    }

    // String result = xxtea.decryptToString(resultContainer.data.toString(), key2);
    String result = resultContainer.data.toString();
    var responseData;
    if (result.isNotEmpty) {
      responseData = jsonDecode(result);
    }

    return HttpResultContainer(resultContainer.statusCode, data: responseData,
        err: resultContainer.err,
        headers: resultContainer.headers,
        isSuccess: resultContainer.isSuccess
    );
  }
}