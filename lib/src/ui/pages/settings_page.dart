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
  DateTime? _lastBackupAt;
  int _syncLogRefresh = 0;

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
                '诊断信息',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '遇到同步、AI 补全或数据库问题时，可以复制一份诊断信息。报告只包含配置是否存在、数量统计和最近错误，不会包含 API Key 明文。',
                style: TextStyle(color: ReciteColors.muted),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _copyDiagnostics,
                  icon: const Icon(Icons.bug_report_rounded),
                  label: const Text('复制诊断信息'),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '安装为 App',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '网站已按 PWA 配置。部署到 HTTPS 后，可以通过浏览器菜单安装到桌面或手机主屏幕；基础页面资源会缓存，断网时也能打开应用和本地数据库。',
                style: TextStyle(color: ReciteColors.muted),
              ),
              const SizedBox(height: 12),
              const _PwaHint(
                icon: Icons.install_desktop_rounded,
                title: '电脑端',
                body: 'Chrome / Edge 地址栏右侧或菜单里选择“安装应用”。',
              ),
              const SizedBox(height: 8),
              const _PwaHint(
                icon: Icons.add_to_home_screen_rounded,
                title: '手机端',
                body: 'iOS 用 Safari 分享菜单“添加到主屏幕”；Android 用 Chrome 菜单“安装应用”。',
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
                    '当前待 AI 补全 / 需复核：$queued 个。每次最多处理 10 个，低质量结果会标记为需复核，不会进入正常学习。',
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
                '可以用 JSON 手动备份和恢复当前浏览器里的词库。导入前会先预览内容，覆盖导入会二次确认。',
                style: TextStyle(color: ReciteColors.muted),
              ),
              const SizedBox(height: 10),
              _SettingsRow(
                icon: Icons.restore_page_rounded,
                label: '上次导出',
                value: _lastBackupLabel(_lastBackupAt),
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
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _syncColor(
                          syncState,
                        ).withValues(alpha: 0.12),
                        foregroundColor: _syncColor(syncState),
                        child: Icon(_syncIcon(syncState)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supabase 同步',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _syncStatusLabel(syncState),
                              style: TextStyle(color: _syncColor(syncState)),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  const SizedBox(height: 12),
                  _SyncTips(tips: _syncTips(syncState)),
                  const SizedBox(height: 12),
                  FutureBuilder<List<SyncLogEntry>>(
                    key: ValueKey(_syncLogRefresh),
                    future: store.getSyncLogs(),
                    builder: (context, snapshot) {
                      return _SyncLogList(entries: snapshot.data ?? const []);
                    },
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
    final lastBackupAt = await store.getLastBackupAt();
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
      _lastBackupAt = lastBackupAt;
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
      _syncLogRefresh += 1;
    });
  }

  Future<void> _exportData() async {
    final store = AppScope.of(context);
    final json = await store.exportBackupJson();
    await Clipboard.setData(ClipboardData(text: json));
    final now = DateTime.now();
    await store.saveLastBackupAt(now);
    if (!mounted) {
      return;
    }
    setState(() {
      _lastBackupAt = now;
      _status = '备份 JSON 已复制到剪贴板。';
    });
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
    BackupPreview? preview;
    String? previewError;
    _BackupImportChoice choice = _BackupImportChoice.cancel;
    final store = AppScope.of(context);
    choice =
        await showDialog<_BackupImportChoice>(
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          try {
                            final nextPreview = store.previewBackupJson(
                              controller.text,
                            );
                            setDialogState(() {
                              preview = nextPreview;
                              previewError = null;
                            });
                          } on Object catch (error) {
                            setDialogState(() {
                              preview = null;
                              previewError = '无法读取备份：$error';
                            });
                          }
                        },
                        icon: const Icon(Icons.fact_check_rounded),
                        label: const Text('预览内容'),
                      ),
                    ),
                    if (previewError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        previewError!,
                        style: const TextStyle(color: ReciteColors.orange),
                      ),
                    ],
                    if (preview != null) ...[
                      const SizedBox(height: 12),
                      _BackupPreviewPanel(preview: preview!),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, _BackupImportChoice.cancel),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: preview == null
                      ? null
                      : () =>
                            Navigator.pop(context, _BackupImportChoice.replace),
                  child: const Text('覆盖导入'),
                ),
                FilledButton(
                  onPressed: preview == null
                      ? null
                      : () => Navigator.pop(context, _BackupImportChoice.merge),
                  child: const Text('合并导入'),
                ),
              ],
            ),
          ),
        ) ??
        _BackupImportChoice.cancel;
    if (choice == _BackupImportChoice.cancel || !mounted) {
      controller.dispose();
      return;
    }
    final replace = choice == _BackupImportChoice.replace;
    if (replace) {
      final confirmedReplace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认覆盖当前数据？'),
          content: const Text('覆盖导入会先清空当前浏览器里的词库和复习记录，再写入备份内容。建议确认已经导出现有数据。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认覆盖'),
            ),
          ],
        ),
      );
      if (confirmedReplace != true || !mounted) {
        controller.dispose();
        return;
      }
    }
    try {
      final result = await AppScope.of(
        context,
      ).importBackupJson(controller.text, replace: replace);
      setState(() => _status = result.message);
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

  Future<void> _copyDiagnostics() async {
    try {
      final report = await AppScope.of(context).buildDiagnosticReport();
      await Clipboard.setData(ClipboardData(text: report));
      if (!mounted) {
        return;
      }
      setState(() => _status = '诊断信息已复制。');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _status = '诊断信息生成失败：$error');
    }
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
  return _formatLocalDateTime(value);
}

String _lastBackupLabel(DateTime? value) {
  if (value == null) {
    return '尚未导出';
  }
  return _formatLocalDateTime(value);
}

String _formatLocalDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}.$month.$day $hour:$minute';
}

Color _syncColor(SyncState state) {
  switch (state.phase) {
    case SyncPhase.idle:
      return state.pendingChanges == 0 ? ReciteColors.teal : ReciteColors.blue;
    case SyncPhase.syncing:
      return ReciteColors.blue;
    case SyncPhase.notConfigured:
      return ReciteColors.orange;
    case SyncPhase.failed:
      return ReciteColors.orange;
  }
}

IconData _syncIcon(SyncState state) {
  switch (state.phase) {
    case SyncPhase.idle:
      return state.pendingChanges == 0
          ? Icons.cloud_done_rounded
          : Icons.cloud_upload_rounded;
    case SyncPhase.syncing:
      return Icons.sync_rounded;
    case SyncPhase.notConfigured:
      return Icons.cloud_off_rounded;
    case SyncPhase.failed:
      return Icons.error_outline_rounded;
  }
}

List<String> _syncTips(SyncState state) {
  switch (state.phase) {
    case SyncPhase.idle:
      if (state.pendingChanges == 0) {
        return const ['云同步已就绪。本地和云端没有待处理变更。'];
      }
      return [
        '有 ${state.pendingChanges} 条本地变更等待上传，建议点击“立即同步”。',
        '如果准备换设备或清浏览器数据，先导出一份 JSON 备份。',
      ];
    case SyncPhase.syncing:
      return const ['正在同步，请保持页面打开，完成前不要清空本地数据。'];
    case SyncPhase.notConfigured:
      return const [
        '先确认已经登录账号，并且 Supabase URL、anon key、SQL 表结构都已配置。',
        '在同步完全稳定前，重要修改后建议手动导出 JSON。',
      ];
    case SyncPhase.failed:
      return const [
        '先导出 JSON 保留当前数据，再检查网络、Supabase RLS 权限和表结构。',
        '如果刚改过云端 SQL，重新登录后再点一次“立即同步”。',
      ];
  }
}

enum _BackupImportChoice { cancel, merge, replace }

class _AiModelPreset {
  const _AiModelPreset({required this.provider, required this.model});

  final String provider;
  final String model;
}

class _SyncTips extends StatelessWidget {
  const _SyncTips({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ReciteColors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: ReciteColors.blue),
                SizedBox(width: 8),
                Text('同步建议', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '· $tip',
                  style: const TextStyle(color: ReciteColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PwaHint extends StatelessWidget {
  const _PwaHint({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ReciteColors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(body, style: const TextStyle(color: ReciteColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackupPreviewPanel extends StatelessWidget {
  const _BackupPreviewPanel({required this.preview});

  final BackupPreview preview;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: ReciteColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _PreviewLine(label: '备份版本', value: preview.version.toString()),
            _PreviewLine(
              label: '导出时间',
              value: preview.exportedAt == null
                  ? '未知'
                  : _formatLocalDateTime(preview.exportedAt!),
            ),
            _PreviewLine(
              label: '单词',
              value:
                  '${preview.wordCount} 个 · 自建 ${preview.personalWordCount} · 词书 ${preview.bookWordCount}',
            ),
            _PreviewLine(
              label: '补全来源',
              value:
                  'AI ${preview.aiWordCount} · 词典 ${preview.dictionaryWordCount}',
            ),
            _PreviewLine(label: '复习记录', value: '${preview.reviewLogCount} 条'),
          ],
        ),
      ),
    );
  }
}

class _SyncLogList extends StatelessWidget {
  const _SyncLogList({required this.entries});

  final List<SyncLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: ReciteColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: ReciteColors.blue),
                SizedBox(width: 8),
                Text('最近同步日志', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              const Text(
                '还没有同步记录。',
                style: TextStyle(color: ReciteColors.muted),
              )
            else
              for (final entry in entries.take(5)) _SyncLogTile(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _SyncLogTile extends StatelessWidget {
  const _SyncLogTile({required this.entry});

  final SyncLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.success ? ReciteColors.teal : ReciteColors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entry.success
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatLocalDateTime(entry.createdAt)} · 上传 ${entry.pushed} · 拉取 ${entry.pulled} · 待同步 ${entry.pendingChanges}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.message,
                  style: const TextStyle(color: ReciteColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(color: ReciteColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
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
