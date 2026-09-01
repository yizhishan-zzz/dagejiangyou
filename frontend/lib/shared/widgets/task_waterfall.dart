import 'package:flutter/material.dart';

import '../../features/tasks/domain/task_models.dart';

class TaskWaterfall extends StatelessWidget {
  const TaskWaterfall({
    super.key,
    required this.tasks,
    required this.itemBuilder,
  });

  final List<NearbyTask> tasks;
  final Widget Function(BuildContext context, NearbyTask task) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 2 : 1;
        if (columns == 1) {
          return Column(
            children: [
              for (final task in tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: itemBuilder(context, task),
                ),
            ],
          );
        }

        final left = <NearbyTask>[];
        final right = <NearbyTask>[];
        for (var index = 0; index < tasks.length; index++) {
          (index.isEven ? left : right).add(tasks[index]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _WaterfallColumn(tasks: left, builder: itemBuilder),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _WaterfallColumn(tasks: right, builder: itemBuilder),
            ),
          ],
        );
      },
    );
  }
}

class _WaterfallColumn extends StatelessWidget {
  const _WaterfallColumn({required this.tasks, required this.builder});

  final List<NearbyTask> tasks;
  final Widget Function(BuildContext context, NearbyTask task) builder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final task in tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: builder(context, task),
          ),
      ],
    );
  }
}
