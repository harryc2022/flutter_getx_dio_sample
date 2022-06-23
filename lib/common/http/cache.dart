/*
 *  Copyright (C), 2015-2021
 *  FileName: cache
 *  Author: Tonight丶相拥
 *  Date: 2021/3/15
 *  Description: 
 **/

import 'dart:async';
import 'dart:io';
import 'package:httpplugin/httpplugin.dart';
import 'package:get_storage/get_storage.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class AppCacheManager with CacheBase {
  static AppCacheManager? _cache;
  static AppCacheManager get cache => _cache ?? _getInstance();
  AppCacheManager._();

  GetStorage _storage = GetStorage();

  // 获取单例
  static AppCacheManager _getInstance() {
    _cache = AppCacheManager._();
    return _cache!;
  }

  // 用户token
  final String _userToken = "hjn_user_token";

  final String _isGuestlogin = "guest_login";

  // app 语言
  final String _appLanguage = "app_language";
  // ------------------设置------------------------
  // 是否开启应用锁
  final String _isLockOpen = "_isLockOpen";
  // 是否开启震动
  final String _isShakeOpen = "_isShakeOpen";
  // 是否开启礼物特效
  final String _isGiftOpen = "_isGiftOpen";
  // 是否驾驶特效
  final String _isDriveOpen = "_isDriveOpen";

  // ------------------投注,预设倍数------------------------
  final String _presetMultiplier = "_presetMultiplier";

  /// 预设倍数
  void setPresetMul(List<String> value) async {
    _storage.write(_presetMultiplier, value);
  }

  /// 获取预设倍数
  List<String> getPresetMul() {
    List<dynamic>? list = _storage.read(_presetMultiplier);
    if ((list?.length ?? 0) > 0) {
      List<String> items = [];
      list!.forEach((element) {
        items.add("$element");
      });
      return items;
    } else {
      return [];
    }
  }

  /// 删除预设倍数
  void removePresetMul() {
    _storage.remove(_presetMultiplier);
  }

  // 是否开启应用锁
  void setisLockOpen(bool value) async {
    _storage.write(_isLockOpen, value);
  }

  bool? getisLockOpen() {
    return _storage.read(_isLockOpen);
  }

  // 是否开启震动
  void setisShakeOpen(bool value) async {
    _storage.write(_isShakeOpen, value);
  }

  bool? getiShakeOpen() {
    return _storage.read(_isShakeOpen);
  }

  // 是否开启礼物特效
  void setisGiftOpen(bool value) async {
    _storage.write(_isGiftOpen, value);
  }

  bool? getiGiftOpen() {
    return _storage.read(_isGiftOpen);
  }

// 是否开启礼物特效
  void setisDriveOpen(bool value) async {
    _storage.write(_isDriveOpen, value);
  }

  bool? getiDriveOpen() {
    return _storage.read(_isDriveOpen);
  }

  // 设置token
  void setUserToken(String token) async {
    _storage.write(_userToken, token);
  }

  String? getUserToken() {
    return _storage.read(_userToken);
  }

  // 设置token
  void setisGuest(bool isguest) async {
    _storage.write(_isGuestlogin, isguest);
  }

  bool? getisGuest() {
    bool? value;
    try {
      value = _storage.read(_isGuestlogin);
    } catch (_) {
      value = false;
    }
    return value;
  }

  /// 设置语言
  void setAppLanguage(int index) async {
    _storage.write(_appLanguage, index);
  }

  /// 获取app 语言设置
  int? getAppLanguage() {
    int? value;
    try {
      value = _storage.read(_appLanguage);
    } catch (_) {}
    return value;
  }

  @override
  String getValueForKey(String key) {
    // TODO: implement getValueForKey
    return "";
  }

  @override
  void setValueForKey(String key, String value) {
    // TODO: implement setValueForKey
  }

  /// 加载缓存大小
  Future<_CacheEntity> loadCacheSize() async {
    /// 获取临时文件路径
    Directory tempDir = await getTemporaryDirectory();

    /// 获取临时文件的大小
    double size = await _getSize(tempDir);

    /// 返回临时文件大小格式转换
    return renderSize(size);
  }

  /// 递归获取所有文件
  Future<double> _getSize(FileSystemEntity file) async {
    if (file is File) {
      int length = await file.length();
      return length.toDouble();
    } else if (file is Directory) {
      if (file.path.endsWith("libCachedImageData")) {
        return 0;
      }

      /// 文件路径下面的所有文件
      final Iterator<FileSystemEntity> children = file.listSync().iterator;
      double total = 0;
      while (children.moveNext()) {
        FileSystemEntity entity = children.current;

        /// 递归获取
        total += await _getSize(entity);
      }
      return total;
    }
    return 0;
  }

  /// 计算文件大小
  _CacheEntity renderSize(double? size) {
    List<String> unit = ["B", "K", "M", "G"];
    if (size == null) {
      return _CacheEntity(cacheSize: 0, unit: unit[0]);
    } else {
      int index = 0;
      while (size! > 1024) {
        index++;
        size = size / 1024;
      }

      /// 保留两位小数
      double value = (size * 100).ceil() / 100;

      /// 返回模型
      return _CacheEntity(unit: unit[index], cacheSize: value);
    }
  }

  /// 清除缓存
  Future<Null> clearCache() async {
    Directory tempDir = await getTemporaryDirectory();
    await _delDir(tempDir);
  }

  /// 递归删除文件
  Future<Null> _delDir(FileSystemEntity file) async {
    if (file is Directory) {
      if (file.path.endsWith("libCachedImageData")) {
        return;
      }

      /// 获取文件路径下所有文件
      Iterator<FileSystemEntity> iterator = file.listSync().iterator;
      while (iterator.moveNext()) {
        FileSystemEntity entity = iterator.current;

        /// 递归删除
        await _delDir(entity);
      }
    }
    try {
      /// 删除文件夹
      await file.delete();
    } catch (e) {
      print("delete error $e");
    }
  }
}

class _CacheEntity {
  _CacheEntity({this.cacheSize: 0, this.unit: "B"});

  /// 缓存大小
  final double cacheSize;

  /// 缓存大小单位
  final String unit;
}
