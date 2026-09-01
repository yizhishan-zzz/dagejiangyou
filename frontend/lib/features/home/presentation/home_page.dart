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
import '../../location/presentation/location_picker_page.dart';
import '../../marketplace/presentation/marketplace_page.dart';
import '../../pools/presentation/pool_state.dart';
import '../../tasks/domain/task_models.dart';
import '../../tasks/presentation/task_detail_page.dart';
import '../../tasks/presentation/task_state.dart';
import '../../user/presentation/user_state.dart';
import '../domain/service_catalog.dart';
import 'publish_task_sheet.dart';
import 'service_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskState>();
    final pools = context.watch<PoolState>();
    final ads = context.watch<AdState>();
    final user = context.watch<UserState>();
    final profile = user.profile;
    final homeAds = ads.slotsFor('HOME_TOP');
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          tasks.refreshNearby(),
          pools.refreshShowcase(),
          user.refreshProfile(silent: true),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 116),
        children: [
          _WelcomeHeader(
            name: profile?.displayName ?? '邻里朋友',
            community: profile?.communityName ?? '选择所在社区',
            building: profile?.buildingName,
            onLocationTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LocationPickerPage()),
            ),
          ),
          if (homeAds.isNotEmpty) ...[
            const SizedBox(height: 16),
            AdBanner(
              ad: homeAds.first,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MarketplacePage()),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _PrimaryAction(
            isCreator: user.isCreator,
            taskCount: user.isCreator
                ? tasks.myTasks.length
                : tasks.nearbyTasks.length,
            onTap: () => user.isCreator
                ? showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const PublishTaskSheet(),
                  )
                : Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MarketplacePage()),
                  ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(title: '快捷服务', subtitle: ''),
          const SizedBox(height: 12),
          _ServiceCollage(
            entries: serviceCatalog,
            onTap: (entry) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ServiceDetailPage(entry: entry),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: user.isCreator ? '我的发布' : '顺路可接',
            subtitle: '',
            trailing: StatusChip(
              label:
                  '${user.isCreator ? tasks.myTasks.length : tasks.nearbyTasks.length} 条',
              color: user.isCreator
                  ? BauhausColors.coral
                  : BauhausColors.cobalt,
            ),
          ),
          const SizedBox(height: 12),
          if (tasks.errorMessage != null)
            BauhausPanel(
              color: const Color(0xFFFFDBD8),
              child: Text(tasks.errorMessage!),
            )
          else if (user.isCreator && tasks.myTasks.isEmpty)
            const _EmptyAction(icon: Icons.add_task_rounded, label: '还没有发布任务')
          else if (user.isRunner && tasks.nearbyTasks.isEmpty)
            const _EmptyAction(
              icon: Icons.explore_off_rounded,
              label: '附近暂无可接任务',
            )
          else if (user.isCreator)
            ...tasks.myTasks
                .take(4)
                .map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OwnedTaskItem(task: task),
                  ),
                )
          else
            TaskWaterfall(
              tasks: tasks.nearbyTasks.take(8).toList(),
              itemBuilder: (context, task) => _TaskFeedItem(task: task),
            ),
          const SizedBox(height: 20),
          const SectionHeader(title: '正在拼单', subtitle: ''),
          const SizedBox(height: 12),
          if (pools.showcasePools.isEmpty)
            const _EmptyAction(icon: Icons.group_off_rounded, label: '附近暂无拼单')
          else
            ...pools.showcasePools
                .take(2)
                .map(
                  (pool) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BauhausPanel(
                      accent: BauhausColors.yellow,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pool.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Text('${pool.remainingSlots} 个名额'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: pool.progress.clamp(0, 1),
                            minHeight: 9,
                            backgroundColor: Colors.white,
                            color: BauhausColors.cobalt,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${pool.currentParticipants}/${pool.targetParticipants} 人已加入',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.name,
    required this.community,
    required this.building,
    required this.onLocationTap,
  });

  final String name;
  final String community;
  final String? building;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Stack(
        children: [
          Positioned(
            right: 2,
            top: 2,
            child: Transform.rotate(
              angle: .11,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: BauhausColors.yellow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: BauhausColors.ink, width: 2.5),
                ),
                child: const Center(
                  child: GeometricMark(color: BauhausColors.coral, size: 38),
                ),
              ),
            ),
          ),
          Positioned.fill(
            right: 74,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 7),
                InkWell(
                  onTap: onLocationTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, size: 18),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            building == null
                                ? community
                                : '$community · $building',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.expand_more_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.isCreator,
    required this.taskCount,
    required this.onTap,
  });

  final bool isCreator;
  final int taskCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isCreator ? BauhausColors.coral : BauhausColors.cobalt;
    return PressableScale(
      onTap: onTap,
      child: BauhausPanel(
        color: color,
        padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCreator ? '需要搭把手？' : '附近有 $taskCount 个活儿',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCreator ? '发布一个任务' : '看看顺不顺路',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isCreator ? BauhausColors.yellow : BauhausColors.mint,
                shape: BoxShape.circle,
                border: Border.all(color: BauhausColors.ink, width: 2.5),
              ),
              child: Icon(
                isCreator ? Icons.add_rounded : Icons.arrow_forward_rounded,
                color: BauhausColors.ink,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCollage extends StatelessWidget {
  const _ServiceCollage({required this.entries, required this.onTap});

  final List<ServiceEntry> entries;
  final ValueChanged<ServiceEntry> onTap;

  @override
  Widget build(BuildContext context) {
    const colors = [
      BauhausColors.yellow,
      BauhausColors.coral,
      BauhausColors.mint,
      BauhausColors.cobalt,
      BauhausColors.lilac,
      Color(0xFFFF8BCB),
      Color(0xFF8ED8FF),
      Color(0xFFFFA95A),
      Color(0xFFB9E769),
      Color(0xFFFFF0A8),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final wide = constraints.maxWidth >= 720;
        final columns = wide ? 4 : 2;
        final unit = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < entries.length; index++)
              SizedBox(
                width: _isWideTile(index, wide) ? unit * 2 + gap : unit,
                height: _tileHeight(index),
                child: Transform.rotate(
                  angle: index % 3 == 0 ? -.012 : (index % 3 == 1 ? .01 : 0),
                  child: _ServiceTile(
                    entry: entries[index],
                    color: colors[index % colors.length],
                    onTap: () => onTap(entries[index]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _isWideTile(int index, bool wide) =>
      wide ? index == 0 || index == 7 : index == 0 || index == 5;

  double _tileHeight(int index) => switch (index % 4) {
    0 => 142,
    1 => 118,
    2 => 132,
    _ => 112,
  };
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.entry,
    required this.color,
    required this.onTap,
  });

  final ServiceEntry entry;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onDark = color == BauhausColors.cobalt;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: BauhausColors.ink, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: BauhausColors.ink,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -2,
              top: -2,
              child: CollageServiceIcon(
                icon: entry.icon,
                color: onDark ? BauhausColors.yellow : BauhausColors.coral,
                size: 48,
              ),
            ),
            Positioned.fill(
              right: 46,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onDark ? Colors.white : BauhausColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onDark ? Colors.white : BauhausColors.ink,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFeedItem extends StatelessWidget {
  const _TaskFeedItem({required this.task});
  final NearbyTask task;

  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailPage(taskId: task.taskId, preview: task),
      ),
    ),
    child: BauhausPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                AppFormatters.money(task.suggestedTip),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: BauhausColors.coral),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${AppFormatters.distance(task.distanceMeters)} · ${AppFormatters.taskTypeLabel(task.taskType)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _OwnedTaskItem extends StatelessWidget {
  const _OwnedTaskItem({required this.task});
  final TaskRecord task;

  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: task.taskId)),
    ),
    child: BauhausPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 42,
            decoration: BoxDecoration(
              color: AppFormatters.taskStatusColor(task.status),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.taskStatusLabel(task.status),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(AppFormatters.money(task.escrowAmount)),
          const SizedBox(width: 5),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    ),
  );
}

class _EmptyAction extends StatelessWidget {
  const _EmptyAction({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
    ),
  );
}
