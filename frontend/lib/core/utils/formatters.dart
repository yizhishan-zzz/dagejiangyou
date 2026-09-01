import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../features/pools/data/pool_repository.dart';
import '../../features/tasks/domain/task_models.dart';
import '../../features/user/domain/user_profile.dart';

class AppFormatters {
  static final _money = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
  static final _time = DateFormat('HH:mm');

  static String money(num value) => _money.format(value);

  static String distance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  static String compactNumber(num value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}万';
    }
    return value.toStringAsFixed(0);
  }

  static String clock(DateTime value) => _time.format(value);

  static String modeLabel(UserMode mode) => switch (mode) {
    UserMode.creator => '发布者',
    UserMode.runner => '跑者',
  };

  static String otpPurposeLabel(OtpPurpose purpose) => switch (purpose) {
    OtpPurpose.login => '登录',
    OtpPurpose.register => '注册',
  };

  static String taskTypeLabel(TaskType type) => switch (type) {
    TaskType.packagePickup => '快递 / 外卖代拿',
    TaskType.errand => '万能帮办',
    TaskType.pool => '社区拼单',
  };

  static String taskStatusLabel(TaskStatus status) => switch (status) {
    TaskStatus.open => '待接单',
    TaskStatus.accepted => '已接单',
    TaskStatus.pickedUp => '已取货',
    TaskStatus.arrived => '已到达',
    TaskStatus.completed => '已完成',
    TaskStatus.cancelled => '已取消',
  };

  static Color taskStatusColor(TaskStatus status) => switch (status) {
    TaskStatus.open => BauhausColors.blue,
    TaskStatus.accepted => BauhausColors.yellow,
    TaskStatus.pickedUp => BauhausColors.blue,
    TaskStatus.arrived => BauhausColors.red,
    TaskStatus.completed => BauhausColors.ink,
    TaskStatus.cancelled => BauhausColors.red,
  };

  static String poolStatusLabel(PoolStatus status) => switch (status) {
    PoolStatus.open => '招募中',
    PoolStatus.full => '已满员',
    PoolStatus.closed => '已结束',
  };
}
