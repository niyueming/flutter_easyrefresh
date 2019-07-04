import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyrefresh/src/footer/load_indicator.dart';

import '../../easy_refresh.dart';

/// Header
abstract class Footer {
  // Footer容器高度
  final double extent;
  // 高度(超过这个高度出发刷新)
  final double triggerDistance;
  // 是否浮动
  final bool float;
  // 完成延时
  final Duration completeDuration;

  Footer({
    this.extent = 60.0,
    this.triggerDistance = 70.0,
    this.float = false,
    this.completeDuration,
  });

  // 构造器
  Widget builder(BuildContext context, EasyRefresh easyRefresh) {
    return EasyRefreshSliverLoadControl(
      loadIndicatorExtent: extent,
      loadTriggerPullDistance: triggerDistance,
      builder: contentBuilder,
      completeDuration: completeDuration,
      onLoad: easyRefresh.onLoad,
      bindLoadIndicator: (finishLoad) {
        if (easyRefresh.controller != null) {
          easyRefresh.controller.finishLoad = finishLoad;
        }
      },
    );
  }

  // Header构造器
  Widget contentBuilder(
      BuildContext context,
      LoadIndicatorMode refreshState,
      double pulledExtent,
      double refreshTriggerPullDistance,
      double refreshIndicatorExtent,
      );
}

/// 通用Footer构造器
class CustomFooter extends Footer {

  /// Header构造器
  final LoadControlIndicatorBuilder headerBuilder;

  CustomFooter({
    extent = 60.0,
    triggerDistance = 70.0,
    float = false,
    completeDuration,
    @required this.headerBuilder,
  }) : super (
    extent: extent,
    triggerDistance: triggerDistance,
    float: float,
    completeDuration: completeDuration,
  );

  @override
  Widget contentBuilder(BuildContext context,
      LoadIndicatorMode refreshState, double pulledExtent,
      double refreshTriggerPullDistance, double refreshIndicatorExtent) {
    return headerBuilder(context, refreshState, pulledExtent,
        refreshTriggerPullDistance, refreshIndicatorExtent);
  }
}

/// 经典Footer
class ClassicalFooter extends Footer {

  ClassicalFooter({
    extent = 60.0,
    triggerDistance = 70.0,
    float = false,
    completeDuration,
  }): super(
    extent: extent,
    triggerDistance: triggerDistance,
    float: float,
    completeDuration: completeDuration,
  );

  @override
  Widget contentBuilder(BuildContext context, LoadIndicatorMode refreshState,
      double pulledExtent, double refreshTriggerPullDistance,
      double refreshIndicatorExtent) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Color(0xFF000000),
    );
  }
}