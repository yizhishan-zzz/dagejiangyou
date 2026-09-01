import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/shell_background.dart';
import '../../../shared/widgets/status_chip.dart';
import '../domain/chat_models.dart';
import 'chat_state.dart';
import '../../tasks/domain/task_models.dart';
import '../../tasks/presentation/task_state.dart';
import '../../user/presentation/user_state.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final taskState = context.watch<TaskState>();
    final userState = context.watch<UserState>();
    final chatState = context.watch<ChatState>();
    final trackedTask = taskState.trackedTask;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        chatState.loadForTask(trackedTask);
      }
    });
    final threads = _buildThreads(trackedTask: taskState.trackedTask);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 980;
        final tracker = _OrderTrackerCard(
          trackedTask: taskState.trackedTask,
          isRunner: userState.isRunner,
          isBusy: taskState.isMutating,
          onPickedUp: () =>
              taskState.updateTrackedTaskStatus(TaskStatus.pickedUp),
          onArrived: () => taskState.updateTrackedTaskStatus(
            TaskStatus.arrived,
            proofToken: 'proof-${DateTime.now().millisecondsSinceEpoch}',
          ),
          onConfirm: taskState.confirmTrackedTask,
        );

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 340, child: _ThreadList(threads: threads)),
                const SizedBox(width: 18),
                Expanded(
                  child: ListView(
                    children: [
                      tracker,
                      const SizedBox(height: 16),
                      _ConversationPanel(
                        trackedTask: taskState.trackedTask,
                        messages: chatState.messages,
                        isLoading: chatState.isLoading,
                        isSending: chatState.isSending,
                        errorMessage: chatState.errorMessage,
                        currentUserId: chatState.currentUserId,
                        onSend: trackedTask == null
                            ? null
                            : (body) =>
                                  chatState.sendForTask(trackedTask, body),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text('消息', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            tracker,
            const SizedBox(height: 16),
            _ThreadList(threads: threads),
            const SizedBox(height: 16),
            _ConversationPanel(
              trackedTask: taskState.trackedTask,
              messages: chatState.messages,
              isLoading: chatState.isLoading,
              isSending: chatState.isSending,
              errorMessage: chatState.errorMessage,
              currentUserId: chatState.currentUserId,
              onSend: trackedTask == null
                  ? null
                  : (body) => chatState.sendForTask(trackedTask, body),
            ),
          ],
        );
      },
    );
  }

  List<_MessageThread> _buildThreads({required TaskRecord? trackedTask}) {
    final threads = <_MessageThread>[];
    if (trackedTask != null) {
      threads.add(
        _MessageThread(
          title: trackedTask.title,
          preview: '当前状态：${AppFormatters.taskStatusLabel(trackedTask.status)}',
          timeLabel: '进行中',
          unread: 1,
        ),
      );
    }
    return threads;
  }
}

class _MessageThread {
  const _MessageThread({
    required this.title,
    required this.preview,
    required this.timeLabel,
    required this.unread,
  });

  final String title;
  final String preview;
  final String timeLabel;
  final int unread;
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({required this.threads});

  final List<_MessageThread> threads;

  @override
  Widget build(BuildContext context) {
    return BauhausPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最近消息', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          if (threads.isEmpty) const Text('暂无消息'),
          ...threads.map(
            (thread) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: BauhausColors.blue),
                    child: Center(
                      child: Text(
                        thread.title.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          thread.preview,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        thread.timeLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (thread.unread > 0) ...[
                        const SizedBox(height: 8),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: BauhausColors.red,
                          child: Text(
                            '${thread.unread}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTrackerCard extends StatelessWidget {
  const _OrderTrackerCard({
    required this.trackedTask,
    required this.isRunner,
    required this.isBusy,
    required this.onPickedUp,
    required this.onArrived,
    required this.onConfirm,
  });

  final TaskRecord? trackedTask;
  final bool isRunner;
  final bool isBusy;
  final Future<void> Function() onPickedUp;
  final Future<void> Function() onArrived;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final task = trackedTask;
    return BauhausPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('任务进度', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              StatusChip(
                label: task == null
                    ? '等待任务'
                    : AppFormatters.taskStatusLabel(task.status),
                color: task == null
                    ? BauhausColors.blue
                    : AppFormatters.taskStatusColor(task.status),
                icon: Icons.local_shipping_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task == null
                ? '暂无进行中任务'
                : '${task.title} · ${AppFormatters.money(task.escrowAmount)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (task == null)
            const Text('暂无进行中的履约任务')
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StepPill(
                  title: '已接单',
                  active: task.status.index >= TaskStatus.accepted.index,
                ),
                _StepPill(
                  title: '已取货',
                  active: task.status.index >= TaskStatus.pickedUp.index,
                ),
                _StepPill(
                  title: '已到达',
                  active: task.status.index >= TaskStatus.arrived.index,
                ),
                _StepPill(
                  title: '已完成',
                  active: task.status.index >= TaskStatus.completed.index,
                ),
              ],
            ),
          if (task != null) ...[
            const SizedBox(height: 18),
            if (isRunner && task.status == TaskStatus.accepted)
              FilledButton(
                onPressed: isBusy
                    ? null
                    : () => _handleAction(context, onPickedUp),
                child: const Text('我已取货'),
              ),
            if (isRunner && task.status == TaskStatus.pickedUp)
              FilledButton(
                onPressed: isBusy
                    ? null
                    : () => _handleAction(context, onArrived),
                child: const Text('已到门口并上传凭证'),
              ),
            if (!isRunner && task.status == TaskStatus.arrived)
              FilledButton(
                onPressed: isBusy
                    ? null
                    : () => _handleAction(context, onConfirm),
                child: const Text('确认送达并结算'),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final taskState = context.read<TaskState>();
    await action();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(taskState.errorMessage ?? '状态已更新')));
  }
}

class _ConversationPanel extends StatefulWidget {
  const _ConversationPanel({
    required this.trackedTask,
    required this.messages,
    required this.isLoading,
    required this.isSending,
    required this.errorMessage,
    required this.currentUserId,
    required this.onSend,
  });

  final TaskRecord? trackedTask;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final String currentUserId;
  final Future<bool> Function(String body)? onSend;

  @override
  State<_ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<_ConversationPanel> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.trackedTask;
    return BauhausPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('任务会话', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (widget.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.errorMessage!,
                style: const TextStyle(color: BauhausColors.red),
              ),
            ),
          if (task == null)
            const Text('暂无进行中的任务会话')
          else if (widget.messages.isEmpty && !widget.isLoading)
            const Text('还没有消息，先和对方确认取货位置吧。')
          else
            ...widget.messages.map(_messageBubble),
          if (task != null) ...[
            const SizedBox(height: 14),
            if (widget.onSend == null)
              const Text('任务接单后才可以发送消息。')
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        hintText: '输入消息',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: BauhausColors.yellow,
                      border: Border.all(color: BauhausColors.ink, width: 3),
                    ),
                    child: IconButton(
                      tooltip: '发送消息',
                      onPressed: widget.isSending ? null : _send,
                      icon: widget.isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _messageBubble(ChatMessage message) {
    final mine = message.senderId == widget.currentUserId;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: mine ? BauhausColors.yellow : Colors.white,
          border: Border.all(color: BauhausColors.ink, width: 3),
        ),
        child: Text(message.body),
      ),
    );
  }

  Future<void> _send() async {
    final onSend = widget.onSend;
    if (onSend == null || _messageController.text.trim().isEmpty) return;
    final sent = await onSend(_messageController.text);
    if (sent && mounted) {
      _messageController.clear();
    }
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.title, required this.active});

  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? BauhausColors.yellow : Colors.white,
        border: Border.all(color: BauhausColors.ink, width: 3),
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: BauhausColors.ink),
      ),
    );
  }
}
