// import 'dart:async';
//
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// class ConnectivityManager {
//   /// 实例
//   static ConnectivityManager? _connectivity;
//
//   /// 实例对外开放
//   static ConnectivityManager get instance => _getInstance();
//
//   /// 获取实例
//   static ConnectivityManager _getInstance() {
//     if (_connectivity == null) {
//       _connectivity = ConnectivityManager._();
//     }
//     return _connectivity!;
//   }
//
//   /// 网络状态
//   ConnectivityResult? _connectivityState;
//
//   /// 当前网络是否为WiFi
//   bool get isWifi => _connectivityState == ConnectivityResult.wifi;
//
//   /// 是否是移动网络
//   bool get isMobile => _connectivityState == ConnectivityResult.mobile;
//
//   /// 是否是无网络
//   bool get none => _connectivityState == ConnectivityResult.none;
//
//   /// 订阅者
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;
//
//   /// 禁止初始化
//   ConnectivityManager._();
//
//   /// 开始监听
//   Future<void> startListenNetWorkState([void Function()? netWorkChange]) async {
//     _connectivitySubscription =
//         Connectivity().onConnectivityChanged.listen((state) {
//       _connectivityState = state;
//       if (netWorkChange != null) netWorkChange();
//     });
//
//     /// 当前网络状态
//     _connectivityState = await Connectivity().checkConnectivity();
//     return;
//   }
//
//   /// 移除观察者
//   void removeListenNetWork() {
//     _connectivitySubscription?.cancel();
//   }
// }
