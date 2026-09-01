import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_background.dart';
import 'user_state.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _loginPhone = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerPhone = TextEditingController();
  final _registerPassword = TextEditingController();
  final _registerName = TextEditingController();
  bool _isRegistering = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    for (final controller in [
      _loginPhone,
      _loginPassword,
      _registerPhone,
      _registerPassword,
      _registerName,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserState>();
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 48,
              28,
              compact ? 20 : 48,
              40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: compact
                  ? Column(
                      children: [
                        _brandPanel(context),
                        const SizedBox(height: 24),
                        _formPanel(context, state),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _brandPanel(context)),
                        const SizedBox(width: 32),
                        Expanded(flex: 6, child: _formPanel(context, state)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandPanel(BuildContext context) {
    return BauhausPanel(
      color: BauhausColors.red,
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GeometricMark(color: BauhausColors.yellow, size: 42),
              const SizedBox(width: 14),
              Text(
                '打个酱油',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 44),
          Text(
            '邻里之间，顺手就能办。',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontSize: 42,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 24),
          const SlashedDivider(color: Colors.white),
        ],
      ),
    );
  }

  Widget _formPanel(BuildContext context, UserState state) {
    return BauhausPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isRegistering ? '创建账号' : '欢迎回来',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _modeTab(
                  context,
                  '登录',
                  !_isRegistering,
                  () => setState(() => _isRegistering = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeTab(
                  context,
                  '注册',
                  _isRegistering,
                  () => setState(() => _isRegistering = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _isRegistering
                ? _registerForm(context, state)
                : _loginForm(context, state),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 18),
            BauhausPanel(
              color: const Color(0xFFFFE2DF),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: BauhausColors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: BauhausColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeTab(
    BuildContext context,
    String title,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? BauhausColors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: BauhausColors.ink, width: 2.5),
        ),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }

  Widget _loginForm(BuildContext context, UserState state) {
    return Column(
      key: const ValueKey('login'),
      children: [
        TextField(
          controller: _loginPhone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: '手机号'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _loginPassword,
          obscureText: true,
          decoration: const InputDecoration(labelText: '密码'),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.isAuthenticating ? null : () => _login(context),
            child: Text(state.isAuthenticating ? '正在进入...' : '登录'),
          ),
        ),
      ],
    );
  }

  Widget _registerForm(BuildContext context, UserState state) {
    return Column(
      key: const ValueKey('register'),
      children: [
        TextField(
          controller: _registerName,
          decoration: const InputDecoration(labelText: '昵称'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _registerPhone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: '手机号'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _registerPassword,
          obscureText: true,
          decoration: const InputDecoration(labelText: '密码（至少 8 位，含字母和数字）'),
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _termsAccepted,
          onChanged: (value) => setState(() => _termsAccepted = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('我已阅读并同意服务条款与隐私政策'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.isAuthenticating ? null : () => _register(context),
            child: Text(state.isAuthenticating ? '正在创建...' : '创建账号'),
          ),
        ),
      ],
    );
  }

  Future<void> _login(BuildContext context) async {
    if (_loginPhone.text.trim().isEmpty || _loginPassword.text.isEmpty) {
      _showMessage('请输入手机号和密码');
      return;
    }
    await context.read<UserState>().loginWithPassword(
      phoneNumber: _loginPhone.text.trim(),
      password: _loginPassword.text,
    );
  }

  Future<void> _register(BuildContext context) async {
    if (_registerName.text.trim().isEmpty ||
        _registerPhone.text.trim().isEmpty ||
        _registerPassword.text.isEmpty) {
      _showMessage('请补全昵称、手机号和密码');
      return;
    }
    if (!_termsAccepted) {
      _showMessage('请先同意服务条款与隐私政策');
      return;
    }
    await context.read<UserState>().register(
      phoneNumber: _registerPhone.text.trim(),
      password: _registerPassword.text,
      displayName: _registerName.text.trim(),
      communityName: '',
      buildingName: '',
      termsAccepted: true,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
