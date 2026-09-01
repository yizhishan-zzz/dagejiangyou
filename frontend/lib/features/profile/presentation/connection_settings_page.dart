import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_settings.dart';
import '../../../shared/widgets/shell_background.dart';
import '../../pools/presentation/pool_state.dart';
import '../../tasks/presentation/task_state.dart';
import '../../user/presentation/user_state.dart';

class ConnectionSettingsPage extends StatefulWidget {
  const ConnectionSettingsPage({super.key});

  @override
  State<ConnectionSettingsPage> createState() => _ConnectionSettingsPageState();
}

class _ConnectionSettingsPageState extends State<ConnectionSettingsPage> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _userIdController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettings>();
    _baseUrlController = TextEditingController(text: settings.baseUrl);
    _userIdController = TextEditingController(text: settings.userId);
    _latitudeController = TextEditingController(text: '${settings.latitude}');
    _longitudeController = TextEditingController(text: '${settings.longitude}');
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _userIdController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('服务连接')),
      body: AppBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            BauhausPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('连接参数', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '可根据当前部署方式调整服务地址。本机访问建议使用 127.0.0.1，局域网联调可切换至内网地址。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(labelText: '当前用户 ID'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latitudeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: '纬度'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _longitudeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: '经度'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('保存并同步数据')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final settings = context.read<AppSettings>();
    final userState = context.read<UserState>();
    final taskState = context.read<TaskState>();
    final poolState = context.read<PoolState>();
    await settings.saveConnection(
      baseUrl: _baseUrlController.text,
      userId: _userIdController.text,
      latitude: double.tryParse(_latitudeController.text) ?? settings.latitude,
      longitude:
          double.tryParse(_longitudeController.text) ?? settings.longitude,
    );
    if (!mounted) {
      return;
    }
    await userState.refreshProfile();
    await taskState.refreshNearby();
    await poolState.refreshShowcase();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('连接参数已保存并完成同步')));
  }
}
