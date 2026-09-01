import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/shell_background.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../user/presentation/user_state.dart';
import '../domain/task_models.dart';
import 'task_state.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.taskId, this.preview});
  final String taskId;
  final NearbyTask? preview;
  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  TaskRecord? _task;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final task = await context.read<TaskState>().loadTaskDetail(widget.taskId);
    if (!context.mounted) return;
    setState(() {
      _task = task;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TaskState>();
    final userState = context.watch<UserState>();
    final tracked = state.trackedTask;
    final task = tracked?.taskId == widget.taskId ? tracked : _task;
    return Scaffold(
      appBar: AppBar(title: const Text('任务详情')),
      body: AppBackdrop(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : task == null
            ? Center(child: Text(state.errorMessage ?? '任务暂时无法查看'))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                  children: [
                    _header(context, task),
                    const SizedBox(height: 16),
                    _statusRail(context, task),
                    const SizedBox(height: 16),
                    _information(context, task),
                    if (!task.isPublic && task.taskCode != null) ...[
                      const SizedBox(height: 16),
                      _privateCode(context, task.taskCode!),
                    ],
                    const SizedBox(height: 16),
                    _actionPanel(context, task, state, userState),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header(BuildContext context, TaskRecord task) {
    final accent = task.taskType == TaskType.pool
        ? BauhausColors.brandSoft
        : BauhausColors.brand;
    final foreground = task.taskType == TaskType.pool
        ? BauhausColors.ink
        : Colors.white;
    return BauhausPanel(
      color: accent,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(
                label: AppFormatters.taskTypeLabel(task.taskType),
                color: BauhausColors.ink,
              ),
              const Spacer(),
              Text(
                AppFormatters.money(task.suggestedTip),
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: foreground),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            task.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: foreground),
          ),
          const SizedBox(height: 8),
          Text(
            task.description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }

  Widget _statusRail(BuildContext context, TaskRecord task) {
    final steps = [
      (TaskStatus.open, '待接单'),
      (TaskStatus.accepted, '已接单'),
      (TaskStatus.pickedUp, '已取货'),
      (TaskStatus.arrived, '已到达'),
      (TaskStatus.completed, '已完成'),
    ];
    return BauhausPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('履约进度', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          for (final item in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    color: task.status.index >= item.$1.index
                        ? BauhausColors.brand
                        : Colors.white,
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(color: BauhausColors.ink, width: 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(item.$2, style: Theme.of(context).textTheme.bodyLarge),
                  if (task.status == item.$1) ...[
                    const SizedBox(width: 10),
                    StatusChip(label: '当前', color: BauhausColors.brandSoft),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _information(BuildContext context, TaskRecord task) {
    return BauhausPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('服务信息', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _infoRow(
            context,
            '楼层',
            '取货 ${task.pickupFloor} 楼  /  送达 ${task.dropoffFloor} 楼',
          ),
          _infoRow(context, '重量', '${task.weightKg.toStringAsFixed(1)} kg'),
          _infoRow(
            context,
            '费用',
            '托管 ${AppFormatters.money(task.escrowAmount)}',
          ),
          _infoRow(context, '隐私', '交付前仅展示必要信息'),
          _infoRow(context, '可见性', task.isPublic ? '附近公开任务' : '私密点对点任务'),
          if (task.photoProofToken != null) _infoRow(context, '凭证', '已上传履约凭证'),
        ],
      ),
    );
  }

  Widget _privateCode(BuildContext context, String code) {
    return BauhausPanel(
      color: BauhausColors.brandSoft,
      child: Row(
        children: [
          const Icon(Icons.key_rounded, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('私密任务码', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                SelectableText(
                  code,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: BauhausColors.brandDark,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '复制任务码',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('任务码已复制')));
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _actionPanel(
    BuildContext context,
    TaskRecord task,
    TaskState state,
    UserState userState,
  ) {
    final busy = state.isMutating;
    Widget? action;
    if (userState.isRunner &&
        task.status == TaskStatus.open &&
        !task.isCreator) {
      action = FilledButton(
        onPressed: busy
            ? null
            : () => _run(context, () => state.acceptTaskId(task.taskId), '已接单'),
        child: Text(busy ? '处理中...' : '立即接单'),
      );
    } else if (userState.isRunner &&
        task.isRunner &&
        task.status == TaskStatus.accepted) {
      action = FilledButton(
        onPressed: busy
            ? null
            : () => _run(
                context,
                () => state.updateTrackedTaskStatus(TaskStatus.pickedUp),
                '已更新为取货',
              ),
        child: Text(busy ? '处理中...' : '我已取货'),
      );
    } else if (userState.isRunner &&
        task.isRunner &&
        task.status == TaskStatus.pickedUp) {
      action = FilledButton(
        onPressed: busy
            ? null
            : () => _run(
                context,
                () => state.updateTrackedTaskStatus(TaskStatus.arrived),
                '已到达，凭证已生成',
              ),
        child: Text(busy ? '处理中...' : '到达并提交凭证'),
      );
    } else if (userState.isCreator &&
        task.isCreator &&
        task.status == TaskStatus.arrived) {
      action = FilledButton(
        onPressed: busy
            ? null
            : () => _run(context, state.confirmTrackedTask, '已确认送达，结算完成'),
        child: Text(busy ? '结算中...' : '确认送达并结算'),
      );
    } else if (userState.isCreator &&
        task.isCreator &&
        task.status == TaskStatus.open) {
      action = OutlinedButton(
        onPressed: busy
            ? null
            : () => _run(
                context,
                () => state.cancelTask(task.taskId),
                '任务已取消，托管金额已退回',
              ),
        child: Text(busy ? '处理中...' : '取消任务'),
      );
    }
    return BauhausPanel(
      child: action == null
          ? Text('当前账号暂无可执行操作。', style: Theme.of(context).textTheme.bodyMedium)
          : SizedBox(width: double.infinity, child: action),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() operation,
    String success,
  ) async {
    await operation();
    if (!context.mounted) return;
    final error = context.read<TaskState>().errorMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? success)));
    if (error == null) await _load();
  }
}
