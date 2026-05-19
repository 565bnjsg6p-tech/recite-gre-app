import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/auth_repository.dart';
import '../../data/sync_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_card.dart';

const _noModelValue = '__no_model__';
const _customModelValue = '__custom_model__';

const _modelPresets = [
  _AiModelPreset(provider: 'OpenAI', model: 'gpt-4.1-mini'),
  _AiModelPreset(provider: 'OpenAI', model: 'gpt-4o-mini'),
  _AiModelPreset(provider: 'OpenAI', model: 'gpt-4o'),
  _AiModelPreset(provider: 'DeepSeek', model: 'deepseek-chat'),
  _AiModelPreset(provider: 'Qwen', model: 'qwen-plus'),
  _AiModelPreset(provider: 'Qwen', model: 'qwen-turbo'),
  _AiModelPreset(provider: 'Gemini', model: 'gemini-2.5-flash'),
  _AiModelPreset(provider: 'Claude', model: 'claude-3-5-haiku-latest'),
];

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.onChangeLanguage,
  });

  final AppUser user;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onChangeLanguage;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiBaseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _customModelController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEnriching = false;
  bool _isSyncing = false;
  String _selectedModel = _noModelValue;
  String _status = '';
  String _syncMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadSettings();
    }
  }

  @override
  void dispose() {
    _apiBaseUrlController.dispose();
    _apiKeyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return PageScaffold(
      title: '设置',
      subtitle: '账号、同步、AI 和数据备份',
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '账号',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.user.displayName} · ${widget.user.email}',
                style: const TextStyle(color: ReciteColors.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onChangeLanguage,
                    icon: const Icon(Icons.translate_rounded),
                    label: const Text('切换语言'),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onSignOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('退出登录'),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI 接口配置',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '接口地址、Key 和模型都手动填写或选择。当前会通过你自己的 Pages 代理转发，适合自用和更换不同代理商。',
                style: TextStyle(color: ReciteColors.muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _apiBaseUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'https://api.gptsapi.net',
                  helperText: '支持填写根地址，也支持完整 /v1/chat/completions 地址。',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedModel,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '模型',
                  prefixIcon: Icon(Icons.memory_rounded),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _noModelValue,
                    child: Text('请选择模型'),
                  ),
                  for (final preset in _modelPresets)
                    DropdownMenuItem(
                      value: preset.model,
                      child: Text('${preset.provider} · ${preset.model}'),
                    ),
                  const DropdownMenuItem(
                    value: _customModelValue,
                    child: Text('自定义模型名'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedModel = value ?? _noModelValue;
                  });
                },
              ),
              if (_selectedModel == _customModelValue) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customModelController,
                  decoration: const InputDecoration(
                    labelText: '自定义模型名',
                    hintText: '例如 gpt-4o、deepseek-chat、qwen-plus',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                '下拉菜单只是常用模型名模板，最终是否可用取决于你的代理商和账号权限。',
                style: TextStyle(color: ReciteColors.muted),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : () => _saveSettings(store),
                  icon: const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? '保存中' : '保存设置'),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<DashboardStats>(
          stream: store.watchDashboardStats(),
          builder: (context, snapshot) {
            final queued = snapshot.data?.queuedForAi ?? 0;
            return SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 补全队列',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '当前待 AI 补全：$queued 个。每次最多处理 10 个，避免一次消耗太多 token。',
                    style: const TextStyle(color: ReciteColors.muted),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isEnriching || queued == 0
                          ? null
                          : _runAiEnrichment,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text(_isEnriching ? '补全中' : '一键 AI 补全'),
                    ),
                  ),
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _status,
                      style: const TextStyle(color: ReciteColors.muted),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Web 数据备份',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '登录同步接入前，可以用 JSON 手动备份和恢复当前浏览器里的词库。',
                style: TextStyle(color: ReciteColors.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('导出 JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _importData,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('导入 JSON'),
                  ),
                  FilledButton.icon(
                    onPressed: _clearData,
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text('清空数据'),
                  ),
                ],
              ),
            ],
          ),
        ),
        StreamBuilder<SyncState>(
          stream: store.watchSyncStatus(),
          builder: (context, snapshot) {
            final syncState =
                snapshot.data ??
                const SyncState(
                  phase: SyncPhase.notConfigured,
                  pendingChanges: 0,
                  message: '同步状态加载中。',
                );
            return SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsRow(
                    icon: Icons.cloud_sync_rounded,
                    label: 'Supabase 同步',
                    value: _syncStatusLabel(syncState),
                  ),
                  const Divider(height: 24),
                  _SettingsRow(
                    icon: Icons.history_rounded,
                    label: '上次同步',
                    value: _lastSyncLabel(syncState.lastSyncedAt),
                  ),
                  const Divider(height: 24),
                  const _SettingsRow(
                    icon: Icons.storage_rounded,
                    label: '本地数据库',
                    value: 'Drift · 已按账号隔离',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _isSyncing || syncState.phase == SyncPhase.syncing
                          ? null
                          : _runSync,
                      icon: const Icon(Icons.sync_rounded),
                      label: Text(_isSyncing ? '同步中' : '立即同步'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _syncMessage.isEmpty ? syncState.message : _syncMessage,
                    style: const TextStyle(color: ReciteColors.muted),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _loadSettings() async {
    final store = AppScope.of(context);
    final apiBaseUrl = await store.getApiBaseUrl();
    final apiKey = await store.getApiKey();
    final model = await store.getModel();
    if (!mounted) {
      return;
    }
    setState(() {
      _apiBaseUrlController.text = apiBaseUrl;
      _apiKeyController.text = apiKey;
      if (model.isEmpty) {
        _selectedModel = _noModelValue;
      } else if (_modelPresets.any((preset) => preset.model == model)) {
        _selectedModel = model;
      } else {
        _selectedModel = _customModelValue;
        _customModelController.text = model;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(AppStore store) async {
    setState(() {
      _isSaving = true;
      _status = '';
    });
    await store.saveApiBaseUrl(_apiBaseUrlController.text);
    await store.saveApiKey(_apiKeyController.text);
    await store.saveModel(_currentModelValue());
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _status = '设置已保存到当前浏览器。';
    });
  }

  String _currentModelValue() {
    if (_selectedModel == _customModelValue) {
      return _customModelController.text.trim();
    }
    if (_selectedModel == _noModelValue) {
      return '';
    }
    return _selectedModel;
  }

  Future<void> _runAiEnrichment() async {
    final store = AppScope.of(context);
    setState(() {
      _isEnriching = true;
      _status = '正在补全，请保持页面打开。';
    });
    final result = await store.enrichQueuedAiWords();
    if (!mounted) {
      return;
    }
    setState(() {
      _isEnriching = false;
      _status = result.message;
    });
  }

  Future<void> _runSync() async {
    final store = AppScope.of(context);
    setState(() {
      _isSyncing = true;
      _syncMessage = '正在检查同步配置。';
    });
    final result = await store.syncNow();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSyncing = false;
      _syncMessage = result.message;
    });
  }

  Future<void> _exportData() async {
    final store = AppScope.of(context);
    final json = await store.exportBackupJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('已复制备份 JSON'),
        content: SizedBox(
          width: 560,
          child: SelectableText(json, maxLines: 12),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    var replace = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('导入备份 JSON'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  minLines: 8,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: '粘贴 JSON',
                    alignLabelWithHint: true,
                  ),
                ),
                CheckboxListTile(
                  value: replace,
                  onChanged: (value) =>
                      setDialogState(() => replace = value ?? false),
                  title: const Text('先清空现有数据'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('导入'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) {
      controller.dispose();
      return;
    }
    try {
      await AppScope.of(
        context,
      ).importBackupJson(controller.text, replace: replace);
      setState(() => _status = '数据导入完成。');
    } on Object catch (error) {
      setState(() => _status = '导入失败：$error');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有本地数据？'),
        content: const Text('这会删除当前浏览器里的词库和复习记录。建议先导出 JSON 备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await AppScope.of(context).clearAllData();
    setState(() => _status = '本地数据已清空。');
  }
}

String _syncStatusLabel(SyncState state) {
  final pending = '本地待同步 ${state.pendingChanges} 条';
  switch (state.phase) {
    case SyncPhase.idle:
      return '就绪 · $pending';
    case SyncPhase.syncing:
      return '同步中 · $pending';
    case SyncPhase.notConfigured:
      return '待配置 · $pending';
    case SyncPhase.failed:
      return '失败 · $pending';
  }
}

String _lastSyncLabel(DateTime? value) {
  if (value == null) {
    return '尚未同步';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}.$month.$day $hour:$minute';
}

class _AiModelPreset {
  const _AiModelPreset({required this.provider, required this.model});

  final String provider;
  final String model;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: ReciteColors.blue),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(color: ReciteColors.muted)),
      ],
    );
  }
}
