library httpplugin;

export 'http_mid_buffer/http_mid_buffer.dart'
    show HttpMidBuffer;
export 'http_config/http_config.dart';
export 'cache_manager/cache_manager.dart' show CacheBase;
export 'http_result_container/http_result_container.dart';
export 'plugin_key/plugin_key.dart';
export 'client/client.dart';
export 'http_container/http_container.dart' show GET, POST, HttpTickContainer;
export 'event_notify/event_notify.dart' show EventNotifyClass;
export 'connectivity/connectivity.dart';
export 'exception_collect/exception_collect.dart';
export 'exception_collect/exception_entity.dart';
export 'wrapper_mixin/wrapper_mixin.dart';
export 'response_deal/error_deal.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}
