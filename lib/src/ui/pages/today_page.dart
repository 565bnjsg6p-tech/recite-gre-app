import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/sync_service.dart';
import '../../data/word_book_catalog.dart';
import '../../data/word_entry.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/pronunciation_button.dart';
import '../widgets/section_card.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.onStartReview,
    required this.onStartNewWords,
    required this.onStartDifficult,
    required this.onOpenInput,
  });

  final VoidCallback onStartReview;
  final VoidCallback onStartNewWords;
  final VoidCallback onStartDifficult;
  final VoidCallback onOpenInput;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return StreamBuilder<DashboardStats>(
      stream: store.watchDashboardStats(),
      builder: (context, statsSnapshot) {
        final stats = statsSnapshot.data;

        return StreamBuilder<List<WordEntry>>(
          stream: store.watchDueWords(),
          builder: (context, dueSnapshot) {
            final dueWords = dueSnapshot.data ?? const <WordEntry>[];

            return StreamBuilder<List<WordEntry>>(
              stream: store.watchDifficultWords(),
              builder: (context, difficultSnapshot) {
                final difficultWords =
                    difficultSnapshot.data ?? const <WordEntry>[];

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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                                          label: '困难词',
                                          value: '${stats.difficultWords}',
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
                                              for (final word in dueWords.take(
                                                8,
                                              ))
                                                _WordDetailRow(word: word),
                                            ],
                                          ),
                                  ),
                          ),
                          MetricTile(
                            label: '困难词',
                            value: '${stats?.difficultWords ?? 0}',
                            icon: Icons.local_fire_department_rounded,
                            color: ReciteColors.red,
                            onTap: stats == null
                                ? null
                                : () => _showMetricDetail(
                                    context,
                                    title: '困难词',
                                    icon: Icons.local_fire_department_rounded,
                                    color: ReciteColors.red,
                                    summary: '这些词曾经遗忘、模糊，或易度偏低，适合集中专项练习。',
                                    child: difficultWords.isEmpty
                                        ? const Text('暂时没有困难词。')
                                        : Column(
                                            children: [
                                              for (final word
                                                  in difficultWords.take(8))
                                                _WordDetailRow(word: word),
                                              const SizedBox(height: 10),
                                              SizedBox(
                                                width: double.infinity,
                                                child: FilledButton.icon(
                                                  onPressed:
                                                      widget.onStartDifficult,
                                                  icon: const Icon(
                                                    Icons.play_arrow_rounded,
                                                  ),
                                                  label: const Text('开始困难词练习'),
                                                ),
                                              ),
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
                          crossAxisCount: isWide ? 4 : 1,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: isWide
                              ? 2.05
                              : constraints.maxWidth < 430
                              ? 3.25
                              : 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: tiles,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<StudyPlan>(
                      future: store.getStudyPlan(),
                      builder: (context, planSnapshot) {
                        return StreamBuilder<List<WordEntry>>(
                          stream: store.watchNewWords(),
                          builder: (context, newSnapshot) {
                            return _NewWordPlanCard(
                              words: newSnapshot.data ?? const <WordEntry>[],
                              plannedCount:
                                  planSnapshot.data?.dailyNewWords ?? 0,
                              onStart: widget.onStartNewWords,
                              onOpenInput: widget.onOpenInput,
                            );
                          },
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
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
                                      backgroundColor: ReciteColors.blue
                                          .withValues(alpha: 0.1),
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
                    FutureBuilder<StudyPlan>(
                      future: store.getStudyPlan(),
                      builder: (context, planSnapshot) {
                        final plan = planSnapshot.data;
                        return SectionCard(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cloud_done_rounded,
                                color: ReciteColors.teal,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '每日计划：新词 ${plan?.dailyNewWords ?? 0} 个，系统复习 ${stats?.dueToday ?? 0} 个，困难词 ${stats?.difficultWords ?? 0} 个。待 AI 补全 ${stats?.queuedForAi ?? 0} 个。',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
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
    final progressValue = syncState?.progressValue;
    final progressLabel = syncState?.progressLabel;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          if (phase == SyncPhase.syncing) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 6,
                      backgroundColor: color.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                if (progressLabel != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    progressLabel,
                    style: const TextStyle(
                      color: ReciteColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ],
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

class _NewWordPlanCard extends StatelessWidget {
  const _NewWordPlanCard({
    required this.words,
    required this.plannedCount,
    required this.onStart,
    required this.onOpenInput,
  });

  final List<WordEntry> words;
  final int plannedCount;
  final VoidCallback onStart;
  final VoidCallback onOpenInput;

  @override
  Widget build(BuildContext context) {
    final sourceCounts = <String, int>{};
    for (final word in words) {
      final book = findWordBook(word.bookKey);
      final label = book?.shortLabel ?? '词书';
      sourceCounts[label] = (sourceCounts[label] ?? 0) + 1;
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ReciteColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: ReciteColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日新词',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '计划 $plannedCount 个，当前可学习 ${words.length} 个。',
                      style: const TextStyle(color: ReciteColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (words.isEmpty) ...[
            const Text(
              '当前没有可学习的新词。可以去录入页导入词书，或检查词书是否被暂停。',
              style: TextStyle(color: ReciteColors.muted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenInput,
                icon: const Icon(Icons.library_add_rounded),
                label: const Text('去管理词书'),
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in sourceCounts.entries)
                  Chip(
                    label: Text('${entry.key} ${entry.value}'),
                    side: BorderSide.none,
                    backgroundColor: ReciteColors.teal.withValues(alpha: 0.12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final word in words.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        word.word,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      findWordBook(word.bookKey)?.shortLabel ?? '词书',
                      style: const TextStyle(color: ReciteColors.muted),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('开始学新词'),
              ),
            ),
          ],
        ],
      ),
    );
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
          PronunciationButton(
            word: word.word,
            visualDensity: VisualDensity.compact,
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
