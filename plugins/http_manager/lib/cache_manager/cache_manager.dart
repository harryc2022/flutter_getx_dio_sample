// import 'package:shared_preferences/shared_preferences.dart';
//
// class CacheManager with CacheBase{
//   /// 实例
//   static CacheManager? _manager;
//   static CacheManager get manager => _getInstance();
//
//   /// 存储三方库
//   late SharedPreferences _preferences;
//
//   /// 禁止初始化
//   CacheManager._();
//
//   /// 启动
//   static Future<void> setUpCacheManager() async{
//     if (_manager == null) {
//       _manager = CacheManager._();
//       _manager!._preferences = await SharedPreferences.getInstance();
//     }
//     return null;
//   }
//
//   /// 获取实例
//   static CacheManager _getInstance() {
//     return _manager!;
//   }
//
//   /// 保存
//   void setValueForKey(String key, String value) {
//     _preferences.setString(key, value);
//   }
//
//   /// 获取数据
//   String getValueForKey(String key) {
//     return _preferences.getString(key) ?? "";
//   }
//
//   /// 是否包含 数据
//   bool containKey(String key) {
//     return _preferences.getKeys().contains(key);
//   }
// }

abstract class CacheBase {
  /// 保存数据
  void setValueForKey(String key, String value);
  /// 获取数据
  String? getValueForKey(String key);
}