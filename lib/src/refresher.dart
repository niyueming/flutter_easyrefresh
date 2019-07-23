import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyrefresh/src/footer/load_indicator.dart';
import 'package:flutter_easyrefresh/src/header/refresh_indicator.dart';
import 'footer/footer.dart';
import 'header/header.dart';
import 'listener/scroll_notification_listener.dart';
import 'physics/scroll_physics.dart';

/// 子组件构造器
typedef EasyRefreshChildBuilder = Widget Function(
    BuildContext context, ScrollPhysics physics,
    Widget header, Widget footer);


/// EasyRefresh
/// 下拉刷新,上拉加载组件
class EasyRefresh extends StatefulWidget {
  /// 控制器
  final EasyRefreshController controller;
  /// 刷新回调(null为不开启刷新)
  final RefreshCallback onRefresh;
  /// 加载回调(null为不开启加载)
  final LoadCallback onLoad;
  /// 是否开启控制结束刷新
  final bool enableControlFinishRefresh;
  /// 是否开启控制结束加载
  final bool enableControlFinishLoad;
  /// 任务独立(刷新和加载状态独立)
  final bool taskIndependence;
  /// Header
  final Header header;
  /// Footer
  final Footer footer;
  /// 子组件构造器
  final EasyRefreshChildBuilder builder;

  /// Slivers集合
  final List<Widget> slivers;
  /// 列表方向
  final Axis scrollDirection;
  /// 反向
  final bool reverse;
  final ScrollController scrollController;
  final bool primary;
  final bool shrinkWrap;
  final Key center;
  final double anchor;
  final double cacheExtent;
  final int semanticChildCount;
  final DragStartBehavior dragStartBehavior;


  // 全局默认Header
  static Header _defaultHeader = ClassicalHeader();
  static set defaultHeader(Header header) {
    if (header != null) {
      _defaultHeader = header;
    }
  }
  // 全局默认Footer
  static Footer _defaultFooter = ClassicalFooter();
  static set defaultFooter(Footer footer) {
    if (footer != null) {
      defaultFooter = footer;
    }
  }

  EasyRefresh.custom({
    key,
    this.controller,
    this.onRefresh,
    this.onLoad,
    this.enableControlFinishRefresh = false,
    this.enableControlFinishLoad = false,
    this.taskIndependence = false,
    this.header,
    this.footer,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.scrollController,
    this.primary,
    this.shrinkWrap = false,
    this.center,
    this.anchor = 0.0,
    this.cacheExtent,
    @required this.slivers,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : builder = null;

  EasyRefresh({
    key,
    this.controller,
    this.onRefresh,
    this.onLoad,
    this.enableControlFinishRefresh = false,
    this.enableControlFinishLoad = false,
    this.taskIndependence = false,
    this.scrollController,
    this.header,
    this.footer,
    @required this.builder,
  }) : this.scrollDirection = null, this.reverse = null,
        this.primary = null, this.shrinkWrap = null, this.center = null,
        this.anchor = null, this.cacheExtent = null, this.slivers = null,
        this.semanticChildCount = null, this.dragStartBehavior = null;

  @override
  _EasyRefreshState createState() {
    return _EasyRefreshState();
  }
}

class _EasyRefreshState extends State<EasyRefresh> {

  // Physics
  EasyRefreshPhysics _physics;

  // Header
  Header get _header {
    return widget.header ?? EasyRefresh._defaultHeader;
  }

  // Footer
  Footer get _footer {
    return widget.footer ?? EasyRefresh._defaultFooter;
  }

  // ScrollController
  ScrollController get _scrollerController {
    return widget.scrollController ?? PrimaryScrollController.of(context);
  }

  // 滚动焦点状态
  ValueNotifier<bool> _focusNotifier;
  // 任务状态
  ValueNotifier<bool> _taskNotifier;

  // 初始化
  @override
  void initState() {
     super.initState();
     _focusNotifier = ValueNotifier<bool>(false);
     _taskNotifier = ValueNotifier<bool>(false);
     _physics = EasyRefreshPhysics();
  }

  // 销毁
  void dispose() {
    super.dispose();
    _focusNotifier.dispose();
    _taskNotifier.dispose();
  }

  // 更新依赖
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 绑定控制器
    if (widget.controller != null)
      widget.controller._bindEasyRefreshState(this);
  }

  // 触发刷新
  void callRefresh() {
    _focusNotifier.value = true;
    _scrollerController.animateTo(-(_header.enableInfiniteRefresh ? 0 : 1)
        * _header.triggerDistance - 20.0,
        duration: Duration(milliseconds: 300), curve: Curves.linear)
        .whenComplete((){
      _focusNotifier.value = false;
    });
  }

  // 触发加载
  void callLoadMore() {
    _focusNotifier.value = true;
    _scrollerController.animateTo(_scrollerController.position.maxScrollExtent
        + _footer.triggerDistance + 20.0,
        duration: Duration(milliseconds: 300), curve: Curves.linear)
        .whenComplete((){
      _focusNotifier.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 构建Header和Footer
    var header = widget.onRefresh == null ? null
        : _header.builder(context, widget, _focusNotifier, _taskNotifier);
    var footer = widget.onLoad == null ? null
        : _footer.builder(context, widget, _focusNotifier, _taskNotifier);
    if (widget.builder == null) {
      // 插入Header和Footer
      if (header != null) widget.slivers.insert(0, header);
      if (footer != null) widget.slivers.add(footer);
    }
    return ScrollNotificationListener(
      onNotification: (notification) {
        return true;
      },
      onFocus: (focus) {
        _focusNotifier.value = focus;
      },
      child: widget.builder == null ? CustomScrollView(
        physics: _physics,
        slivers: widget.slivers,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        controller: widget.scrollController,
        primary: widget.primary,
        shrinkWrap: widget.shrinkWrap,
        center: widget.center,
        anchor: widget.anchor,
        cacheExtent: widget.cacheExtent,
        semanticChildCount: widget.semanticChildCount,
        dragStartBehavior: widget.dragStartBehavior,
      ) : widget.builder(context, _physics, header, footer),
    );
  }
}

/// EasyRefresh控制器
class EasyRefreshController {
  /// 触发刷新
  void callRefresh() {
    if (this._easyRefreshState != null) {
      this._easyRefreshState.callRefresh();
    }
  }
  /// 触发加载
  void callLoad() {
    if (this._easyRefreshState != null) {
      this._easyRefreshState.callLoadMore();
    }
  }
  /// 完成刷新
  FinishRefresh finishRefreshCallBack;
  void finishRefresh({
    bool success,
    bool noMore,
  }) {
    if (finishRefreshCallBack != null) {
      finishRefreshCallBack(success: success, noMore: noMore);
    }
  }
  /// 完成加载
  FinishLoad finishLoadCallBack;
  void finishLoad({
    bool success,
    bool noMore,
  }) {
    if (finishLoadCallBack != null) {
      finishLoadCallBack(success: success, noMore: noMore);
    }
  }
  /// 恢复刷新状态(用于没有更多后)
  VoidCallback resetRefreshStateCallBack;
  void resetRefreshState() {
    if (resetRefreshStateCallBack != null) {
      resetRefreshStateCallBack();
    }
  }
  /// 恢复加载状态(用于没有更多后)
  VoidCallback resetLoadStateCallBack;
  void resetLoadState() {
    if (resetLoadStateCallBack != null) {
      resetLoadStateCallBack();
    }
  }

  // 状态
  _EasyRefreshState _easyRefreshState;

  // 绑定状态
  void _bindEasyRefreshState(_EasyRefreshState state) {
    this._easyRefreshState = state;
  }
}
