import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/features/tasks/domain/task_models.dart';
import 'package:frontend/features/user/domain/user_profile.dart';

void main() {
  test('formatters expose localized labels', () {
    expect(AppFormatters.modeLabel(UserMode.creator), '发布者');
    expect(AppFormatters.taskTypeLabel(TaskType.pool), '社区拼单');
    expect(AppFormatters.taskStatusLabel(TaskStatus.arrived), '已到达');
  });
}
