import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/shell_background.dart';
import '../../tasks/domain/task_models.dart';
import '../../tasks/presentation/task_state.dart';

class PublishTaskSheet extends StatefulWidget {
  const PublishTaskSheet({
    super.key,
    this.initialTaskType = TaskType.packagePickup,
    this.suggestedTitle,
    this.suggestedDescription,
    this.ctaLabel,
  });

  final TaskType initialTaskType;
  final String? suggestedTitle;
  final String? suggestedDescription;
  final String? ctaLabel;

  @override
  State<PublishTaskSheet> createState() => _PublishTaskSheetState();
}

class _PublishTaskSheetState extends State<PublishTaskSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _baseFeeController;
  late final TextEditingController _weightController;
  late final TextEditingController _weatherController;
  late final TextEditingController _pickupFloorController;
  late final TextEditingController _dropoffFloorController;
  TaskType _taskType = TaskType.packagePickup;
  bool _pickupElevator = true;
  bool _dropoffElevator = true;
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _taskType = widget.initialTaskType;
    _titleController = TextEditingController(text: widget.suggestedTitle ?? '');
    _descriptionController = TextEditingController(
      text: widget.suggestedDescription ?? '',
    );
    _baseFeeController = TextEditingController(text: '2.0');
    _weightController = TextEditingController(text: '1.0');
    _weatherController = TextEditingController(text: '0.0');
    _pickupFloorController = TextEditingController(text: '1');
    _dropoffFloorController = TextEditingController(text: '7');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _baseFeeController.dispose();
    _weightController.dispose();
    _weatherController.dispose();
    _pickupFloorController.dispose();
    _dropoffFloorController.dispose();
    super.dispose();
  }

  double get _suggestedTip {
    final baseFee = double.tryParse(_baseFeeController.text) ?? 2.0;
    final weightKg = double.tryParse(_weightController.text) ?? 0;
    final weather = double.tryParse(_weatherController.text) ?? 0;
    final pickupFloor = int.tryParse(_pickupFloorController.text) ?? 1;
    final dropoffFloor = int.tryParse(_dropoffFloorController.text) ?? 1;
    final noElevatorPenalty =
        (_pickupElevator ? 0 : pickupFloor * 0.5) +
        (_dropoffElevator ? 0 : dropoffFloor * 0.5);
    return baseFee + noElevatorPenalty + weightKg * 0.3 + weather;
  }

  @override
  Widget build(BuildContext context) {
    final taskState = context.watch<TaskState>();

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BauhausPanel(
        padding: EdgeInsets.zero,
        color: Theme.of(context).brightness == Brightness.dark
            ? BauhausColors.darkPanel
            : BauhausColors.paper,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SlashedDivider(),
                const SizedBox(height: 18),
                Text(
                  '发布即时需求',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: BauhausColors.brand,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: BauhausColors.ink, width: 2.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '建议小费预估',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              AppFormatters.money(_suggestedTip),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<TaskType>(
                  initialValue: _taskType,
                  decoration: const InputDecoration(labelText: '服务类型'),
                  items: TaskType.values
                      .where((type) => type != TaskType.pool)
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(AppFormatters.taskTypeLabel(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _taskType = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '标题'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: '需求说明'),
                ),
                const SizedBox(height: 14),
                Text('谁可以看到', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _VisibilityChoice(
                        selected: _isPublic,
                        icon: Icons.public_rounded,
                        title: '公开任务',
                        subtitle: '展示在附近任务中',
                        onTap: () => setState(() => _isPublic = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _VisibilityChoice(
                        selected: !_isPublic,
                        icon: Icons.key_rounded,
                        title: '私密任务',
                        subtitle: '凭任务码点对点收取',
                        onTap: () => setState(() => _isPublic = false),
                      ),
                    ),
                  ],
                ),
                if (!_isPublic) ...[
                  const SizedBox(height: 10),
                  BauhausPanel(
                    padding: const EdgeInsets.all(12),
                    color: BauhausColors.brandSoft,
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 19),
                        SizedBox(width: 9),
                        Expanded(child: Text('不会出现在附近任务中。发布后把任务码发给指定跑者即可。')),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _baseFeeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: '基础费'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: '重量 kg'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weatherController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: '天气加价'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pickupFloorController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: '取货楼层'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _dropoffFloorController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: '送达楼层'),
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile.adaptive(
                    value: _pickupElevator,
                    onChanged: (value) =>
                        setState(() => _pickupElevator = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('取货点有电梯'),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile.adaptive(
                    value: _dropoffElevator,
                    onChanged: (value) =>
                        setState(() => _dropoffElevator = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('送达点有电梯'),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '取送距离不超过 500 米',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: taskState.isPublishing ? null : _submit,
                    child: Text(
                      taskState.isPublishing
                          ? '正在发布...'
                          : widget.ctaLabel ?? '确认发布',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请补全标题和需求说明')));
      return;
    }

    final settings = context.read<AppSettings>();
    final taskState = context.read<TaskState>();
    final baseFee = double.tryParse(_baseFeeController.text.trim());
    final weightKg = double.tryParse(_weightController.text.trim());
    final weatherSurcharge = double.tryParse(_weatherController.text.trim());
    final pickupFloor = int.tryParse(_pickupFloorController.text.trim());
    final dropoffFloor = int.tryParse(_dropoffFloorController.text.trim());
    if (baseFee == null ||
        weightKg == null ||
        weatherSurcharge == null ||
        pickupFloor == null ||
        dropoffFloor == null ||
        baseFee < 0 ||
        weightKg < 0 ||
        weatherSurcharge < 0 ||
        pickupFloor < 1 ||
        pickupFloor > 99 ||
        dropoffFloor < 1 ||
        dropoffFloor > 99) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请检查费用、重量和楼层信息')));
      return;
    }

    final payload = CreateTaskPayload(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      taskType: _taskType,
      baseFee: baseFee,
      weightKg: weightKg,
      weatherSurcharge: weatherSurcharge,
      pickupFloor: pickupFloor,
      dropoffFloor: dropoffFloor,
      pickupHasElevator: _pickupElevator,
      dropoffHasElevator: _dropoffElevator,
      pickupLatitude: settings.latitude,
      pickupLongitude: settings.longitude,
      dropoffLatitude: settings.latitude + 0.0004,
      dropoffLongitude: settings.longitude + 0.0004,
      isPublic: _isPublic,
    );

    final published = await taskState.publishTask(payload);
    if (!mounted) {
      return;
    }

    if (!published || taskState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(taskState.errorMessage ?? '发布失败，请稍后重试')),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final task = taskState.trackedTask;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_isPublic ? '任务已发布，附近跑者现在可以看到' : '私密任务已创建，请分享任务码'),
      ),
    );
    final code = task?.taskCode;
    if (!_isPublic && code != null && code.isNotEmpty) {
      await showDialog<void>(
        context: navigator.context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('私密任务已创建'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('把下面的任务码发给指定跑者。任务码只用于这一个任务。'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: BauhausColors.brandSoft,
                  border: Border.all(color: BauhausColors.ink, width: 3),
                ),
                child: SelectableText(
                  code,
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('关闭'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(const SnackBar(content: Text('任务码已复制')));
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('复制任务码'),
            ),
          ],
        ),
      );
    }
  }
}

class _VisibilityChoice extends StatelessWidget {
  const _VisibilityChoice({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? BauhausColors.brandSoft
              : Theme.of(context).colorScheme.surface,
          border: Border.all(color: BauhausColors.ink, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: selected ? BauhausColors.brandDark : null),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: selected ? BauhausColors.brandDark : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 3),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
