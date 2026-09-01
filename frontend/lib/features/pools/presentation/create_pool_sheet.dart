import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_background.dart';
import '../data/pool_repository.dart';
import 'pool_state.dart';

class CreatePoolSheet extends StatefulWidget {
  const CreatePoolSheet({super.key});

  @override
  State<CreatePoolSheet> createState() => _CreatePoolSheetState();
}

class _CreatePoolSheetState extends State<CreatePoolSheet> {
  final _titleController = TextEditingController(text: '晚饭轻食拼单');
  final _storeController = TextEditingController(text: '社区便利店');
  final _categoryController = TextEditingController(text: '社区团餐');
  final _summaryController = TextEditingController(
    text: '邻里一起下单，配送费用按参与人数动态分摊。',
  );
  final _pickupController = TextEditingController(text: '小区门厅自提点');
  final _freightController = TextEditingController(text: '6.0');
  final _deliveryController = TextEditingController(text: '3.6');
  final _targetController = TextEditingController(text: '6');
  final _countdownController = TextEditingController(text: '30');

  @override
  void dispose() {
    for (final controller in [
      _titleController,
      _storeController,
      _categoryController,
      _summaryController,
      _pickupController,
      _freightController,
      _deliveryController,
      _targetController,
      _countdownController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poolState = context.watch<PoolState>();
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
                  '发起社区拼单',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '创建后会进入同社区拼单大厅，参与人数变化时系统自动重算人均配送费用。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                _field(_titleController, '拼单主题'),
                const SizedBox(height: 12),
                _field(_storeController, '商家或店铺'),
                const SizedBox(height: 12),
                _field(_categoryController, '分类'),
                const SizedBox(height: 12),
                _field(_summaryController, '拼单说明', minLines: 2, maxLines: 4),
                const SizedBox(height: 12),
                _field(_pickupController, '统一自提点'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(_freightController, '商家运费', decimal: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(_deliveryController, '接力费用', decimal: true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(_targetController, '目标人数')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_countdownController, '有效时长（分钟）')),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: poolState.isJoining ? null : _submit,
                    child: Text(poolState.isJoining ? '正在创建...' : '创建并发布拼单'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool decimal = false,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _submit() async {
    final freightFee = double.tryParse(_freightController.text.trim());
    final deliveryFee = double.tryParse(_deliveryController.text.trim());
    final targetParticipants = int.tryParse(_targetController.text.trim());
    final countdownMinutes = int.tryParse(_countdownController.text.trim());
    final textFields = [
      _titleController,
      _storeController,
      _categoryController,
      _summaryController,
      _pickupController,
    ];
    if (textFields.any((field) => field.text.trim().isEmpty) ||
        freightFee == null ||
        deliveryFee == null ||
        targetParticipants == null ||
        countdownMinutes == null ||
        freightFee < 0 ||
        deliveryFee < 0 ||
        targetParticipants < 2 ||
        targetParticipants > 100 ||
        countdownMinutes < 5 ||
        countdownMinutes > 1440) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请检查拼单内容、费用、人数和有效时长')));
      return;
    }

    final created = await context.read<PoolState>().createPool(
      PoolCreatePayload(
        title: _titleController.text.trim(),
        storeName: _storeController.text.trim(),
        category: _categoryController.text.trim(),
        summary: _summaryController.text.trim(),
        pickupPoint: _pickupController.text.trim(),
        freightFee: freightFee,
        deliveryFee: deliveryFee,
        targetParticipants: targetParticipants,
        countdownMinutes: countdownMinutes,
      ),
    );
    if (!mounted) return;
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<PoolState>().errorMessage ?? '创建失败，请稍后重试'),
        ),
      );
      return;
    }
    final pool = context.read<PoolState>().lastCreatedPool;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '拼单已发布，当前人均配送费用 ${pool?.sharedFeePerUser.toStringAsFixed(2) ?? '-'} 元',
        ),
      ),
    );
  }
}
