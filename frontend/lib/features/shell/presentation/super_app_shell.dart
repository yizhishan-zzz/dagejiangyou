import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_background.dart';
import '../../home/presentation/home_page.dart';
import '../../marketplace/presentation/marketplace_page.dart';
import '../../messages/presentation/messages_page.dart';
import '../../pools/presentation/pool_state.dart';
import '../../profile/presentation/profile_page.dart';
import '../../tasks/presentation/task_state.dart';
import '../../user/presentation/user_state.dart';

class SuperAppShell extends StatefulWidget {
  const SuperAppShell({super.key});

  @override
  State<SuperAppShell> createState() => _SuperAppShellState();
}

class _SuperAppShellState extends State<SuperAppShell> {
  int _currentIndex = 0;
  late final List<Widget> _pages = const [
    HomePage(),
    MarketplacePage(),
    MessagesPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.wait([
        context.read<TaskState>().refreshNearby(),
        context.read<TaskState>().refreshMyTasks(),
        context.read<PoolState>().refreshShowcase(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final primary = userState.isCreator
        ? BauhausColors.coral
        : BauhausColors.cobalt;
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopNav(
                index: _currentIndex,
                primary: primary,
                modeLabel: userState.isCreator ? '发布者模式' : '跑者模式',
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: IndexedStack(index: _currentIndex, children: _pages),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _CollageBottomNav(
        selectedIndex: _currentIndex,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({
    required this.index,
    required this.primary,
    required this.modeLabel,
  });

  final int index;
  final Color primary;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    final labels = ['今天', '任务大厅', '消息', '我的'];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Row(
            children: [
              GeometricMark(color: primary, size: 32),
              const SizedBox(width: 9),
              Text(
                '打个酱油',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: primary),
              ),
              Container(
                width: 2,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                child: Text(
                  labels[index],
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                modeLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollageBottomNav extends StatelessWidget {
  const _CollageBottomNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (label: '首页', icon: Icons.home_work_rounded, color: BauhausColors.yellow),
      (
        label: '接活',
        icon: Icons.move_to_inbox_rounded,
        color: BauhausColors.coral,
      ),
      (
        label: '消息',
        icon: Icons.chat_bubble_rounded,
        color: BauhausColors.cobalt,
      ),
      (label: '我的', icon: Icons.badge_rounded, color: BauhausColors.mint),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? BauhausColors.darkPanel : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white : BauhausColors.ink,
            width: 2.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelected(index),
                    child: Semantics(
                      selected: index == selectedIndex,
                      label: items[index].label,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ProductNavIcon(
                            icon: items[index].icon,
                            selected: index == selectedIndex,
                            color: items[index].color,
                            variant: index,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[index].label,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: index == selectedIndex
                                      ? items[index].color
                                      : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
