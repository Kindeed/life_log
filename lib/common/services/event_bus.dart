import 'dart:async';

/// 轻量级事件总线
/// 模块之间通过发布/订阅事件通信，避免直接持有对方引用
class EventBus {
  EventBus._();
  static final EventBus _instance = EventBus._();
  static EventBus get instance => _instance;

  final _controller = StreamController<AppEvent>.broadcast();

  /// 发布事件
  void fire(AppEvent event) => _controller.add(event);

  /// 订阅事件（返回 StreamSubscription 便于在 dispose 时取消）
  StreamSubscription<AppEvent> on<T extends AppEvent>(
    void Function(T event) handler,
  ) {
    return _controller.stream
        .where((event) => event is T)
        .cast<T>()
        .listen(handler);
  }

  void dispose() => _controller.close();
}

/// 事件基类
abstract class AppEvent {
  const AppEvent();
}

/// 工时数据变更（增/删/改）
class WorkLogChangedEvent extends AppEvent {
  const WorkLogChangedEvent();
}

/// 订阅数据变更
class SubscriptionChangedEvent extends AppEvent {
  const SubscriptionChangedEvent();
}
