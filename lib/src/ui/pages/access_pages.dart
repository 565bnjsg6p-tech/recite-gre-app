import 'package:flutter/material.dart';

import '../../data/auth_repository.dart';
import '../../theme/app_theme.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({
    super.key,
    required this.onEnglish,
    required this.onGerman,
  });

  final VoidCallback onEnglish;
  final VoidCallback onGerman;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _AccessBrand(),
                  const SizedBox(height: 32),
                  Text(
                    '选择学习语言',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '不同语言会拥有独立的词库、计划和同步空间。',
                    style: TextStyle(color: ReciteColors.muted),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 720;
                      final cards = [
                        _LanguageCard(
                          title: '英语',
                          subtitle: 'GRE / IELTS / TOEFL 词库与复习计划',
                          icon: Icons.menu_book_rounded,
                          enabled: true,
                          onTap: onEnglish,
                        ),
                        _LanguageCard(
                          title: '德语',
                          subtitle: '词库正在准备，稍后开放',
                          icon: Icons.translate_rounded,
                          enabled: false,
                          onTap: onGerman,
                        ),
                      ];
                      if (!twoColumns) {
                        return Column(
                          children: [
                            for (final card in cards) ...[
                              card,
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 14),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GermanComingSoonPage extends StatelessWidget {
  const GermanComingSoonPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AccessBrand(),
                  const SizedBox(height: 28),
                  Text(
                    '德语部分暂未开放',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '当前先完成英语学习和账户同步结构，德语会复用同一套登录与云端数据模型。',
                    style: TextStyle(color: ReciteColors.muted),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('返回语言选择'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.authRepository,
    required this.onAuthenticated,
    required this.onBack,
  });

  final AuthRepository authRepository;
  final Future<void> Function(AppUser user) onAuthenticated;
  final VoidCallback onBack;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegistering = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: '返回',
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          const _AccessBrand(compact: true),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _isRegistering ? '创建英语学习账号' : '登录英语学习账号',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '账号由 Supabase 认证保存，后续会继续接入云端词库同步。',
                        style: TextStyle(color: ReciteColors.muted),
                      ),
                      const SizedBox(height: 22),
                      if (_isRegistering) ...[
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '昵称',
                            prefixIcon: Icon(Icons.badge_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '邮箱',
                          prefixIcon: Icon(Icons.mail_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: '密码',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error,
                          style: const TextStyle(color: ReciteColors.red),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: Icon(
                            _isRegistering
                                ? Icons.person_add_rounded
                                : Icons.login_rounded,
                          ),
                          label: Text(
                            _isSubmitting
                                ? '处理中'
                                : (_isRegistering ? '注册并进入' : '登录'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() {
                                  _isRegistering = !_isRegistering;
                                  _error = '';
                                }),
                          child: Text(
                            _isRegistering ? '已有账号，直接登录' : '新用户，创建账号',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = '';
    });

    final result = _isRegistering
        ? await widget.authRepository.register(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _nameController.text,
          )
        : await widget.authRepository.login(
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    if (result.isSuccess) {
      await widget.onAuthenticated(result.user!);
    } else {
      setState(() => _error = result.error);
    }
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? ReciteColors.blue : ReciteColors.line,
            width: enabled ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 32,
              color: enabled ? ReciteColors.blue : ReciteColors.muted,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: ReciteColors.muted)),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(enabled ? '进入' : '稍后开放'),
                const SizedBox(width: 6),
                Icon(
                  enabled
                      ? Icons.arrow_forward_rounded
                      : Icons.schedule_rounded,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessBrand extends StatelessWidget {
  const _AccessBrand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 36 : 44,
          height: compact ? 36 : 44,
          decoration: BoxDecoration(
            color: ReciteColors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.psychology_alt_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          'Recite',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
