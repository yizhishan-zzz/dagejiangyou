import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_background.dart';
import '../../location/presentation/location_picker_page.dart';
import '../../user/domain/user_profile.dart';
import '../../user/presentation/user_state.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _displayNameController = TextEditingController();
  final _avatarEmojiController = TextEditingController();
  final _bioController = TextEditingController();
  final _roomMaskController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _privacyMasked = true;
  bool _seeded = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _avatarEmojiController.dispose();
    _bioController.dispose();
    _roomMaskController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    final profile = context.read<UserState>().profile;
    if (profile != null) {
      _displayNameController.text = profile.displayName;
      _avatarEmojiController.text = profile.avatarEmoji;
      _bioController.text = profile.bio;
      _roomMaskController.text = profile.roomMask ?? '';
      _notificationsEnabled = profile.notificationsEnabled;
      _privacyMasked = profile.privacyMasked;
    }
    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    return Scaffold(
      appBar: AppBar(title: const Text('账号资料设置')),
      body: AppBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            BauhausPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('基础资料', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(labelText: '昵称'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _avatarEmojiController,
                    decoration: const InputDecoration(labelText: '头像字 / Emoji'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: '个人简介'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LocationPickerPage(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BauhausColors.yellow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: BauhausColors.ink,
                          width: 2.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me_rounded),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${userState.profile?.communityName ?? '选择社区'} · ${userState.profile?.buildingName ?? '选择楼栋'}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _roomMaskController,
                    decoration: const InputDecoration(labelText: '门牌遮罩'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            BauhausPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('交互与隐私', style: Theme.of(context).textTheme.titleLarge),
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile.adaptive(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('接收任务和拼单通知'),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile.adaptive(
                      value: _privacyMasked,
                      onChanged: (value) {
                        setState(() => _privacyMasked = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('默认隐藏门牌与手机号'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: userState.isSavingSettings ? null : _save,
              child: Text(userState.isSavingSettings ? '保存中...' : '保存账号设置'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final payload = UserSettingsPayload(
      displayName: _displayNameController.text.trim(),
      avatarEmoji: _avatarEmojiController.text.trim(),
      bio: _bioController.text.trim(),
      roomMask: _roomMaskController.text.trim(),
      notificationsEnabled: _notificationsEnabled,
      privacyMasked: _privacyMasked,
    );

    final success = await context.read<UserState>().updateSettings(payload);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '账号设置已保存'
              : context.read<UserState>().errorMessage ?? '保存失败',
        ),
      ),
    );
    if (success) {
      Navigator.of(context).pop();
    }
  }
}
