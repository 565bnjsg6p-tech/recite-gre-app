import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/mock_repository.dart';
import '../../data/sync_service.dart';
import '../../data/word_entry.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_card.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key, required this.onStartReview});

  final VoidCallback onStartReview;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final plan = MockRepository.studyPlan;

    return StreamBuilder<DashboardStats>(
      stream: store.watchDashboardStats(),
      builder: (context, statsSnapshot) {
        final stats = statsSnapshot.data;

        return StreamBuilder<List<WordEntry>>(
          stream: store.watchDueWords(),
          builder: (context, dueSnapshot) {
            final dueWords = dueSnapshot.data ?? const <WordEntry>[];

            return PageScaffold(
              title: '今日学习',
              subtitle: '保持节奏，比猛冲更可靠',
              action: StreamBuilder<SyncState>(
                stream: store.watchSyncStatus(),
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final syncing =
                      _isSyncing || state?.phase == SyncPhase.syncing;
                  return IconButton.filled(
                    tooltip: syncing ? '同步中' : '立即同步',
                    onPressed: syncing ? null : () => _runSync(store),
                    icon: syncing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                  );
                },
              ),
              children: [
                StreamBuilder<SyncState>(
                  stream: store.watchSyncStatus(),
                  builder: (context, snapshot) {
                    return _SyncStatusCard(state: snapshot.data);
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 720;
                    final tiles = [
                      MetricTile(
                        label: '词库总量',
                        value: '${stats?.totalWords ?? 0}',
                        icon: Icons.auto_stories_rounded,
                        color: ReciteColors.blue,
                        onTap: stats == null
                            ? null
                            : () => _showMetricDetail(
                                context,
                                title: '词库总量',
                                icon: Icons.auto_stories_rounded,
                                color: ReciteColors.blue,
                                summary: '当前词库里的全部单词数。',
                                child: Column(
                                  children: [
                                    _DetailRow(
                                      label: '总词数',
                                      value: '${stats.totalWords}',
                                    ),
                                    _DetailRow(
                                      label: '今日到期',
                                      value: '${stats.dueToday}',
                                    ),
                                    _DetailRow(
                                      label: '待 AI 补全',
                                      value: '${stats.queuedForAi}',
                                    ),
                                    _DetailRow(
                                      label: '本地待同步',
                                      value: '${stats.pendingSync}',
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      MetricTile(
                        label: '今日到期',
                        value: '${stats?.dueToday ?? 0}',
                        icon: Icons.repeat_rounded,
                        color: ReciteColors.teal,
                        onTap: stats == null
                            ? null
                            : () => _showMetricDetail(
                                context,
                                title: '今日到期',
                                icon: Icons.repeat_rounded,
                                color: ReciteColors.teal,
                                summary: '今天需要优先复习的单词。',
                                child: dueWords.isEmpty
                                    ? const Text('今天没有到期单词。')
                                    : Column(
                                        children: [
                                          for (final word in dueWords.take(8))
                                            _WordDetailRow(word: word),
                                        ],
                                      ),
                              ),
                      ),
                      MetricTile(
                        label: '今日完成',
                        value: '${stats?.reviewedToday ?? 0}',
                        icon: Icons.check_circle_rounded,
                        color: ReciteColors.orange,
                        onTap: stats == null
                            ? null
                            : () => _showMetricDetail(
                                context,
                                title: '今日完成',
                                icon: Icons.check_circle_rounded,
                                color: ReciteColors.orange,
                                summary: '今天已经记录的复习次数。',
                                child: Column(
                                  children: [
                                    _DetailRow(
                                      label: '今日完成',
                                      value: '${stats.reviewedToday}',
                                    ),
                                    _DetailRow(
                                      label: '已复习过的单词数',
                                      value: '${stats.reviewedWords}',
                                    ),
                                    _DetailRow(
                                      label: '本地待同步',
                                      value: '${stats.pendingSync}',
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '这个数字来自复习记录，不是单纯打开页面的次数。',
                                      style: TextStyle(
                                        color: ReciteColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ];
                    return GridView.count(
                      crossAxisCount: isWide ? 3 : 1,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: isWide ? 2.45 : 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: tiles,
                    );
                  },
                ),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '下一组复习',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (dueWords.isEmpty)
                        const Text('今天没有到期单词，可以去录入页添加新词。')
                      else
                        for (final word in dueWords.take(5))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        word.word,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        word.chineseMeaning,
                                        style: const TextStyle(
                                          color: ReciteColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(word.dueLabel),
                                  side: BorderSide.none,
                                  backgroundColor: ReciteColors.blue.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: dueWords.isEmpty
                              ? null
                              : widget.onStartReview,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('开始复习'),
                        ),
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_done_rounded,
                        color: ReciteColors.teal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '每日计划：新词 ${plan.dailyNewWords} 个，复习上限 ${plan.dailyReviewLimit} 个。待 AI 补全 ${stats?.queuedForAi ?? 0} 个。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _runSync(AppStore store) async {
    setState(() => _isSyncing = true);
    final result = await store.syncNow();
    if (!mounted) {
      return;
    }
    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '同步完成：上传 ${result.pushed} 条，拉取 ${result.pulled} 条。'
              : result.message,
        ),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.state});

  final SyncState? state;

  @override
  Widget build(BuildContext context) {
    final syncState = state;
    final phase = syncState?.phase ?? SyncPhase.idle;
    final color = switch (phase) {
      SyncPhase.syncing => ReciteColors.blue,
      SyncPhase.failed => Colors.redAccent,
      SyncPhase.notConfigured => ReciteColors.orange,
      SyncPhase.idle => ReciteColors.teal,
    };
    final icon = switch (phase) {
      SyncPhase.syncing => Icons.sync_rounded,
      SyncPhase.failed => Icons.cloud_off_rounded,
      SyncPhase.notConfigured => Icons.cloud_queue_rounded,
      SyncPhase.idle => Icons.cloud_done_rounded,
    };
    final title = switch (phase) {
      SyncPhase.syncing => '正在同步',
      SyncPhase.failed => '同步失败',
      SyncPhase.notConfigured => '等待登录同步',
      SyncPhase.idle =>
        (syncState?.pendingChanges ?? 0) == 0 ? '云端已同步' : '有本地改动待同步',
    };
    final message = syncState?.message ?? '登录后会自动同步云端词库。';
    final lastSynced = syncState?.lastSyncedAt;

    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastSynced == null
                      ? message
                      : '$message 上次同步：${_formatSyncTime(lastSynced)}',
                  style: const TextStyle(color: ReciteColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSyncTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}.$month.$day $hour:$minute';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: ReciteColors.muted),
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

Future<void> _showMetricDetail(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color color,
  required String summary,
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: const TextStyle(color: ReciteColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(child: child),
          ],
        ),
      ),
    ),
  );
}

class _WordDetailRow extends StatelessWidget {
  const _WordDetailRow({required this.word});

  final WordEntry word;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.word,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  word.chineseMeaning,
                  style: const TextStyle(color: ReciteColors.muted),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(word.dueLabel),
            side: BorderSide.none,
            backgroundColor: ReciteColors.blue.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}
