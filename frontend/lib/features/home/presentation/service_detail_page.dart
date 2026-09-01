import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_background.dart';
import '../../user/presentation/user_state.dart';
import '../../pools/presentation/create_pool_sheet.dart';
import '../domain/service_catalog.dart';
import 'publish_task_sheet.dart';

class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({super.key, required this.entry});

  final ServiceEntry entry;

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final heroColor = entry.id == 'pool'
        ? BauhausColors.yellow
        : BauhausColors.blue;
    final heroForeground = heroColor == BauhausColors.yellow
        ? BauhausColors.ink
        : Colors.white;
    return Scaffold(
      appBar: AppBar(title: Text(entry.title)),
      body: AppBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            BauhausPanel(
              padding: const EdgeInsets.all(24),
              color: heroColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CollageServiceIcon(
                        icon: entry.icon,
                        color: BauhausColors.coral,
                        size: 58,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: heroForeground),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.subtitle,
                              style: TextStyle(color: heroForeground),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    entry.tagline,
                    style: TextStyle(color: heroForeground, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            BauhausPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('适合这些事', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...entry.scenes.map(
                    (scene) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: BauhausColors.red,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(scene)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: userState.isTogglingMode
                  ? null
                  : () => _handleAction(context, userState),
              child: Text(userState.isCreator ? entry.ctaLabel : '切换为发布者并发布'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, UserState userState) async {
    if (userState.isRunner) {
      await userState.toggleMode();
      if (!context.mounted || !userState.isCreator) return;
    }
    if (context.mounted) _openAction(context);
  }

  void _openAction(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => entry.id == 'pool'
          ? const CreatePoolSheet()
          : PublishTaskSheet(
              initialTaskType: entry.taskType,
              suggestedTitle: entry.suggestedTitle,
              suggestedDescription: entry.suggestedDescription,
              ctaLabel: entry.ctaLabel,
            ),
    );
  }
}
