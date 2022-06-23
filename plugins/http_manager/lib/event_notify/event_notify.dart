
/// 消息监听问题
mixin _EventNotify {
  /// token 刷新失败
  void onTokenRefreshFailure();

  /// token 刷新成功
  void onTokenRefreshSuccess();
}

abstract class EventNotifyClass implements _EventNotify{
  @override
  void onTokenRefreshFailure() {

  }

  @override
  void onTokenRefreshSuccess() {

  }
}

/// 消息监听者
class EventNotifyListener extends EventNotifyClass{

}
