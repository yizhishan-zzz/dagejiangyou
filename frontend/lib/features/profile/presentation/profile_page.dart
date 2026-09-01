import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/shell_background.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../tasks/presentation/task_detail_page.dart';
import '../../tasks/presentation/task_state.dart';
import '../../messages/presentation/chat_state.dart';
import '../../pools/presentation/pool_state.dart';
import '../../tasks/domain/task_models.dart';
import '../../user/presentation/user_state.dart';
import '../../location/presentation/location_picker_page.dart';
import 'account_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserState>();
    final taskState = context.watch<TaskState>();
    final settings = context.watch<AppSettings>();
    final profile = user.profile;
    final primary = user.isCreator ? BauhausColors.red : BauhausColors.blue;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Text('我的', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        BauhausPanel(
          color: primary,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                alignment: Alignment.center,
                color: BauhausColors.yellow,
                child: Text(
                  profile?.avatarEmoji ?? '邻',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.displayName ?? '邻里用户',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.maskedPhoneNumber ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile?.communityName ?? '社区待完善'} · ${profile?.buildingName ?? '楼栋待完善'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label:
                    '信用 ${AppFormatters.compactNumber(profile?.creditScore ?? 0)}',
                color: BauhausColors.yellow,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BauhausPanel(
          color: user.isCreator
              ? const Color(0xFFFFE2DF)
              : const Color(0xFFDCEBFA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('使用身份', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ModeChoice(
                      label: '发布者',
                      active: user.isCreator,
                      color: BauhausColors.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModeChoice(
                      label: '跑者',
                      active: user.isRunner,
                      color: BauhausColors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: user.isRunner,
                    onChanged: user.isTogglingMode
                        ? null
                        : (_) => _toggleMode(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricPanel(
                title: '信用分',
                value: AppFormatters.compactNumber(profile?.creditScore ?? 0),
                color: BauhausColors.yellow,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricPanel(
                title: user.isCreator ? '发布中' : '可接任务',
                value: user.isCreator
                    ? taskState.myTasks
                          .where(
                            (task) =>
                                task.isCreator &&
                                task.status.index < TaskStatus.completed.index,
                          )
                          .length
                          .toString()
                    : taskState.nearbyTasks.length.toString(),
                color: primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                '我的任务',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: taskState.refreshMyTasks,
              child: const Text('刷新'),
            ),
          ],
        ),
        if (taskState.myTasks.isEmpty)
          const BauhausPanel(child: Text('还没有任务记录。发布需求或接取任务后，记录会显示在这里。'))
        else
          ...taskState.myTasks
              .take(4)
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskDetailPage(taskId: task.taskId),
                      ),
                    ),
                    child: BauhausPanel(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 42,
                            color: AppFormatters.taskStatusColor(task.status),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              task.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            AppFormatters.taskStatusLabel(task.status),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 12),
        _SettingRow(
          title: '所在位置',
          subtitle:
              '${profile?.communityName ?? '选择社区'} · ${profile?.buildingName ?? '选择楼栋'}',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LocationPickerPage())),
        ),
        const SizedBox(height: 10),
        _SettingRow(
          title: '账号资料',
          subtitle: '昵称、头像与隐私',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
          ),
        ),
        const SizedBox(height: 10),
        BauhausPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.dark_mode_outlined),
              const SizedBox(width: 12),
              const Expanded(child: Text('夜间模式')),
              Switch(
                value: settings.isDarkMode,
                onChanged: settings.setDarkMode,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _SettingRow(
          title: '退出账号',
          subtitle: '退出当前设备',
          onTap: () => _logout(context),
          danger: true,
        ),
      ],
    );
  }

  Future<void> _toggleMode(BuildContext context) async {
    await context.read<UserState>().toggleMode();
    if (!context.mounted) return;
    await Future.wait([
      context.read<TaskState>().refreshNearby(),
      context.read<TaskState>().refreshMyTasks(),
    ]);
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出当前账号？'),
        content: const Text('退出后需要重新登录才能查看任务和消息。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !context.mounted) return;
    await context.read<UserState>().logout();
    if (!context.mounted) return;
    context.read<TaskState>().clear();
    context.read<PoolState>().clear();
    context.read<ChatState>().clear();
  }
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.label,
    required this.active,
    required this.color,
  });
  final String label;
  final bool active;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    alignment: Alignment.center,
    color: active ? color : Colors.white,
    child: Text(
      label,
      style: TextStyle(
        color: active ? Colors.white : BauhausColors.ink,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({
    required this.title,
    required this.value,
    required this.color,
  });
  final String title;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => BauhausPanel(
    padding: const EdgeInsets.all(14),
    color: color,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: BauhausPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: danger ? BauhausColors.red : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward),
        ],
      ),
    ),
  );
}
