import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shell_background.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/task_waterfall.dart';
import '../../ads/presentation/ad_banner.dart';
import '../../ads/presentation/ad_state.dart';
import '../../pools/data/pool_repository.dart';
import '../../pools/presentation/pool_state.dart';
import '../../tasks/domain/task_models.dart';
import '../../tasks/presentation/task_detail_page.dart';
import '../../tasks/presentation/task_state.dart';
import '../../user/presentation/user_state.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  _TaskFilter _selectedFilter = _TaskFilter.all;
  int _selectedTab = 0;
  late final TextEditingController _taskCodeController;

  @override
  void initState() {
    super.initState();
    _taskCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _taskCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskState = context.watch<TaskState>();
    final poolState = context.watch<PoolState>();
    final userState = context.watch<UserState>();
    final ads = context.watch<AdState>();
    final filteredTasks = _filterTasks(taskState.nearbyTasks);
    final marketplaceAds = ads.slotsFor('MARKETPLACE_TOP');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('任务大厅', style: Theme.of(context).textTheme.headlineMedium),
          if (marketplaceAds.isNotEmpty) ...[
            const SizedBox(height: 16),
            AdBanner(ad: marketplaceAds.first),
          ],
          const SizedBox(height: 18),
          _MarketplaceTabs(
            selectedIndex: _selectedTab,
            onChanged: (index) => setState(() => _selectedTab = index),
          ),
          if (userState.isRunner && _selectedTab == 0) ...[
            const SizedBox(height: 14),
            _TaskCodeReceiver(
              controller: _taskCodeController,
              busy: taskState.isMutating,
              onReceive: _receivePrivateTask,
            ),
          ],
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            child: KeyedSubtree(
              key: ValueKey(_selectedTab),
              child: _selectedTab == 0
                  ? _buildTaskFeed(context, filteredTasks)
                  : _buildPoolFeed(context, poolState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskFeed(BuildContext context, List<NearbyTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '筛选', subtitle: ''),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _TaskFilter.values.map((filter) {
            return ChoiceChip(
              label: Text(filter.label),
              selected: filter == _selectedFilter,
              onSelected: (_) => setState(() => _selectedFilter = filter),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          const BauhausPanel(child: Text('当前没有符合条件的任务，换个筛选条件看看。'))
        else
          TaskWaterfall(
            tasks: tasks,
            itemBuilder: (context, task) => _MarketplaceTaskCard(task: task),
          ),
      ],
    );
  }

  Widget _buildPoolFeed(BuildContext context, PoolState poolState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '社区拼单', subtitle: ''),
        const SizedBox(height: 14),
        if (poolState.showcasePools.isEmpty)
          const BauhausPanel(child: Text('当前没有开放拼单，稍后再来看看。'))
        else
          ...poolState.showcasePools.map(
            (pool) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MarketplacePoolCard(
                pool: pool,
                onJoin: () => _openJoinSheet(context, pool),
              ),
            ),
          ),
      ],
    );
  }

  List<NearbyTask> _filterTasks(List<NearbyTask> tasks) {
    return tasks.where((task) {
      switch (_selectedFilter) {
        case _TaskFilter.all:
          return true;
        case _TaskFilter.highReward:
          return task.suggestedTip >= 6;
        case _TaskFilter.nearby:
          return task.distanceMeters <= 300;
        case _TaskFilter.urgent:
          return task.suggestedTip >= 4.5 || task.distanceMeters <= 180;
      }
    }).toList();
  }

  Future<void> _receivePrivateTask() async {
    final taskState = context.read<TaskState>();
    final accepted = await taskState.acceptTaskByCode(_taskCodeController.text);
    if (!mounted) return;
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(taskState.errorMessage ?? '任务码不可用')),
      );
      return;
    }
    final taskId = taskState.trackedTask?.taskId;
    _taskCodeController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('任务已收取，可以开始处理了')));
    if (taskId != null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: taskId)));
    }
  }

  Future<void> _openJoinSheet(BuildContext context, PoolShowcase pool) async {
    final quantityController = TextEditingController(text: '1');
    final amountController = TextEditingController(text: '18.8');
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final poolState = context.watch<PoolState>();
          return BauhausPanel(
            padding: EdgeInsets.zero,
            color: Theme.of(context).brightness == Brightness.dark
                ? BauhausColors.darkPanel
                : BauhausColors.paper,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  18,
                  22,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SlashedDivider(),
                    const SizedBox(height: 18),
                    Text(
                      pool.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(pool.summary),
                    const SizedBox(height: 14),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '数量'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: '商品金额'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: poolState.isJoining
                            ? null
                            : () async {
                                final joined = await context
                                    .read<PoolState>()
                                    .joinPool(
                                      poolId: pool.poolId,
                                      quantity:
                                          int.tryParse(
                                            quantityController.text,
                                          ) ??
                                          1,
                                      itemAmount:
                                          double.tryParse(
                                            amountController.text,
                                          ) ??
                                          0,
                                    );
                                if (!context.mounted) {
                                  return;
                                }
                                final message = !joined
                                    ? context.read<PoolState>().errorMessage ??
                                          '加入失败，请稍后重试'
                                    : '加入成功，人均分摊 ${AppFormatters.money(context.read<PoolState>().lastJoinReceipt?.sharedFeePerUser ?? 0)}';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                                if (joined) {
                                  Navigator.of(context).pop();
                                }
                              },
                        child: Text(poolState.isJoining ? '提交中...' : '确认加入拼单'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MarketplaceTabs extends StatelessWidget {
  const _MarketplaceTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['众包任务', '社区拼单'];
    return BauhausPanel(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: PressableScale(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  alignment: Alignment.center,
                  color: selectedIndex == index
                      ? BauhausColors.brandSoft
                      : Colors.transparent,
                  child: Text(
                    labels[index],
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selectedIndex == index
                          ? BauhausColors.brandDark
                          : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskCodeReceiver extends StatelessWidget {
  const _TaskCodeReceiver({
    required this.controller,
    required this.busy,
    required this.onReceive,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) {
    return BauhausPanel(
      color: BauhausColors.brandSoft,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key_rounded),
              const SizedBox(width: 9),
              Text('收取私密任务', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: '输入 8 位任务码',
                    counterText: '',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: busy ? null : onReceive,
                  icon: const Icon(Icons.call_received_rounded),
                  label: Text(busy ? '处理中' : '收取'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TaskFilter {
  all('全部'),
  highReward('高费用'),
  nearby('300m 内'),
  urgent('优先处理');

  const _TaskFilter(this.label);

  final String label;
}

class _MarketplaceTaskCard extends StatelessWidget {
  const _MarketplaceTaskCard({required this.task});

  final NearbyTask task;

  @override
  Widget build(BuildContext context) {
    final taskState = context.read<TaskState>();
    final userState = context.watch<UserState>();
    return BauhausPanel(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskDetailPage(taskId: task.taskId, preview: task),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(
                  label: AppFormatters.taskTypeLabel(task.taskType),
                  color: BauhausColors.yellow,
                ),
                const Spacer(),
                StatusChip(
                  label: AppFormatters.distance(task.distanceMeters),
                  color: BauhausColors.blue,
                  icon: Icons.social_distance_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(task.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(task.description),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(
                  label: '建议费用 ${AppFormatters.money(task.suggestedTip)}',
                  color: BauhausColors.yellow,
                ),
                StatusChip(
                  label: '取 ${task.pickupFloor} 楼 / 送 ${task.dropoffFloor} 楼',
                  color: BauhausColors.blue,
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: userState.isRunner && !taskState.isMutating
                  ? () async {
                      await taskState.acceptTask(task);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            taskState.errorMessage ?? '接单成功，请前往消息中心继续推进状态',
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text(userState.isRunner ? '接单处理' : '切换到跑者后接单'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplacePoolCard extends StatelessWidget {
  const _MarketplacePoolCard({required this.pool, required this.onJoin});

  final PoolShowcase pool;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return BauhausPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(label: pool.category, color: BauhausColors.yellow),
              const Spacer(),
              StatusChip(
                label: AppFormatters.poolStatusLabel(pool.status),
                color: pool.status == PoolStatus.full
                    ? BauhausColors.red
                    : BauhausColors.blue,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(pool.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(pool.storeName),
          const SizedBox(height: 8),
          Text(pool.summary),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: pool.progress.clamp(0, 1),
            minHeight: 12,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? BauhausColors.ink
                : Colors.white,
            color: BauhausColors.blue,
          ),
          const SizedBox(height: 10),
          Text(
            '${pool.currentParticipants}/${pool.targetParticipants} 人 · 自提点 ${pool.pickupPoint}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: pool.status == PoolStatus.full ? null : onJoin,
                  child: Text(
                    pool.status == PoolStatus.full
                        ? '已满员'
                        : '加入拼单 · 人均 ${AppFormatters.money(pool.sharedFeePerUser)}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
