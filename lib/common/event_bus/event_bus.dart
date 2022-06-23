part of appcommon;

class EventBus {
  static EventBus get instance => _getInstance();

  static EventBus? _instance;

  EventBus._internal();

  static EventBus _getInstance() {
    if (_instance == null) {
      _instance = EventBus._internal();
    }
    return _instance!;
  }

  /// 监听者
  Map<String, List<void Function(dynamic)>> _listener = {};

  /// 添加观察者
  void addListener(void Function(dynamic) fn, {String? name}) async {
    if (name == null || name.isEmpty) {
      var dl = _listener[defaultNotification];
      if (dl == null || dl.length == 0) {
        _listener[defaultNotification] = [fn];
      } else {
        _listener[defaultNotification] = dl..add(fn);
      }
    } else {
      var otherLst = _listener[name];
      if (otherLst == null || otherLst.length == 0) {
        _listener[name] = [fn];
      } else {
        _listener[name] = otherLst..add(fn);
      }
    }
  }

  /// 通知观察者
  void notificationListener({String? name, dynamic parameter}) {
    if (name == null || name.isEmpty) {
      var dl = _listener[defaultNotification];
      if (dl != null) {
        dl.forEach((fn) {
          fn(parameter);
        });
      }
    } else {
      var dl = _listener[name];
      if (dl != null) {
        dl.forEach((fn) {
          fn(parameter);
        });
      }
    }
  }

  /// 移除观察者
  void removeListener(void Function(dynamic) fn, {String? name}) {
    if (name == null || name.isEmpty) {
      _listener[defaultNotification]?.remove(fn);
    } else {
      _listener[name]?.remove(fn);
    }
  }

  /// 移除所有监听
  void removeAllListener() {
    _listener.clear();
  }

}

/// 默认监听
const String defaultNotification = "defaultNotification";

/// 首页tab 数据监听
const String homeTabItemChange = "homeTabItemChange";

/// 验证房间成功
const String verifyRoomSuccess = "verifyRoomSuccess";

/// 加入房间成功
const String enterRoomSuccess = "userEnterRoomSuccess";

/// 主播离线
const String liverOffline = "liverOffline";

/// 首页热门游戏更多点击
const String homeHotGameMoreTaped = "homeHotGameMoreTaped";

/// 进入直播间
const String enterRoom = "enterRoom";

/// 中奖
const String winPrize = "winPrize";

/// 赠送礼物
const String givingGift = "givingGift";

/// 游戏超时
const String gameTimeOut = "GameTimeOut";

/// 免费时间已结束
const String freeTimeOut = "freeTimeOut";

/// 切换语言
const String switchLanguage = "switchLanguage";

/// 首页标签切换
const String homeLabelChange = "homeLabelChange";

//快三 开奖结果
const String k3Result = "k3Result";
// 结束时间
const String gameTime = "gameTime";
// 是否封盘
const String canGame = "canGame";

//  Game windowSized
const String gameWindowSize = "gameWindowSize";
