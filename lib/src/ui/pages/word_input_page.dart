import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/word_book_catalog.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_card.dart';

class WordInputPage extends StatefulWidget {
  const WordInputPage({super.key});

  @override
  State<WordInputPage> createState() => _WordInputPageState();
}

class _WordInputPageState extends State<WordInputPage> {
  final _bulkController = TextEditingController();
  ImportMode _mode = ImportMode.dictionary;
  ImportResult? _lastResult;
  WordBookImportResult? _lastBookResult;
  String _bookKey = 'gre';
  bool _isImporting = false;
  bool _isBookImporting = false;
  bool _bookSettingsLoaded = false;
  Set<String> _disabledBookKeys = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bookSettingsLoaded) {
      _bookSettingsLoaded = true;
      _loadBookSettings();
    }
  }

  @override
  void dispose() {
    _bulkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final previewWords = AppStore.parseWords(_bulkController.text);

    return PageScaffold(
      title: '快速录入',
      subtitle: '批量粘贴，选择基础词典或 AI 补全队列',
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _bulkController,
                minLines: 8,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: '单词列表',
                  hintText: '一行一个单词，也可以用空格或逗号分隔',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              SegmentedButton<ImportMode>(
                segments: const [
                  ButtonSegment(
                    value: ImportMode.dictionary,
                    icon: Icon(Icons.menu_book_rounded),
                    label: Text('基础词典'),
                  ),
                  ButtonSegment(
                    value: ImportMode.aiQueue,
                    icon: Icon(Icons.auto_awesome_rounded),
                    label: Text('AI 队列'),
                  ),
                  ButtonSegment(
                    value: ImportMode.queueOnly,
                    icon: Icon(Icons.inbox_rounded),
                    label: Text('只入库'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (value) {
                  setState(() => _mode = value.first);
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Chip(
                    label: Text('识别 ${previewWords.length} 个'),
                    side: BorderSide.none,
                    backgroundColor: ReciteColors.teal.withValues(alpha: 0.12),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _bulkController.text.isEmpty
                        ? null
                        : () {
                            setState(() => _bulkController.clear());
                          },
                    icon: const Icon(Icons.backspace_rounded),
                    label: const Text('清空输入'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isImporting || previewWords.isEmpty
                        ? null
                        : () => _importWords(store),
                    icon: const Icon(Icons.playlist_add_rounded),
                    label: Text(_isImporting ? '导入中' : '导入词库'),
                  ),
                ],
              ),
              if (_lastResult != null) ...[
                const SizedBox(height: 12),
                Text(
                  '已新增 ${_lastResult!.added} 个，词典命中 ${_lastResult!.dictionaryMatched} 个，进入队列 ${_lastResult!.queued} 个，跳过重复 ${_lastResult!.skipped} 个。',
                  style: const TextStyle(color: ReciteColors.muted),
                ),
              ],
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '词书导入',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '把一本书的词一次性导入到“词书词”里，系统会按每日新词量自动分批安排到复习队列。',
                style: const TextStyle(color: ReciteColors.muted),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _bookKey,
                decoration: const InputDecoration(
                  labelText: '选择词书',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                items: [
                  for (final book in wordBookCatalog)
                    DropdownMenuItem(
                      value: book.key,
                      child: Text(
                        _disabledBookKeys.contains(book.key)
                            ? '${book.label}（已暂停）'
                            : book.label,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _bookKey = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              _WordBookStatsList(
                selectedBookKey: _bookKey,
                statsFuture: store.getWordBookStats(),
                onSelect: (bookKey) {
                  setState(() => _bookKey = bookKey);
                },
                onToggle: (bookKey, enabled) =>
                    _toggleBook(store, bookKey, enabled),
              ),
              const SizedBox(height: 6),
              const Text(
                '暂停后的词书不会进入“学新词”抽取；已经导入的词不会被删除。',
                style: TextStyle(color: ReciteColors.muted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isBookImporting ? null : () => _importBook(store),
                  icon: const Icon(Icons.library_add_rounded),
                  label: Text(_isBookImporting ? '导入中' : '导入词书'),
                ),
              ),
              if (_lastBookResult != null) ...[
                const SizedBox(height: 10),
                Text(
                  _lastBookResult!.message,
                  style: const TextStyle(color: ReciteColors.muted),
                ),
              ],
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '导入预览',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final word in previewWords)
                    InputChip(
                      label: Text(word),
                      onDeleted: () {
                        final next = previewWords.where((item) => item != word);
                        _bulkController.text = next.join('\n');
                        setState(() {});
                      },
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
              Text('补全策略', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              const _PipelineItem('基础词典：使用内置 1.2 万考试词条，零 token，录入后立刻可背'),
              const _PipelineItem('AI 队列：先标记为待 AI 补全，配置接口后可一键生成深度卡片'),
              const _PipelineItem('只入库：保留单词，不补内容，后续可再选择词典或 AI 补全'),
              const _PipelineItem('词典补全的单词可以在详情页升级为 AI 补全'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _importWords(AppStore store) async {
    setState(() {
      _isImporting = true;
      _lastResult = null;
    });
    final result = await store.importWords(_bulkController.text, _mode);
    if (!mounted) {
      return;
    }
    setState(() {
      _isImporting = false;
      _lastResult = result;
      if (result.added > 0) {
        _bulkController.clear();
      }
    });
  }

  Future<void> _loadBookSettings() async {
    final disabled = await AppScope.of(context).getDisabledWordBooks();
    if (!mounted) {
      return;
    }
    setState(() => _disabledBookKeys = disabled);
  }

  Future<void> _toggleBook(AppStore store, String bookKey, bool enabled) async {
    await store.setWordBookEnabled(bookKey, enabled);
    if (!mounted) {
      return;
    }
    final disabled = await store.getDisabledWordBooks();
    if (!mounted) {
      return;
    }
    setState(() => _disabledBookKeys = disabled);
  }

  Future<void> _importBook(AppStore store) async {
    setState(() {
      _isBookImporting = true;
      _lastBookResult = null;
    });
    final result = await store.importWordBook(_bookKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _isBookImporting = false;
      _lastBookResult = result;
    });
  }
}

class _WordBookStatsList extends StatelessWidget {
  const _WordBookStatsList({
    required this.selectedBookKey,
    required this.statsFuture,
    required this.onSelect,
    required this.onToggle,
  });

  final String selectedBookKey;
  final Future<List<WordBookStats>> statsFuture;
  final ValueChanged<String> onSelect;
  final void Function(String bookKey, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WordBookStats>>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: LinearProgressIndicator(minHeight: 3),
          );
        }

        final stats = snapshot.data ?? const <WordBookStats>[];
        if (stats.isEmpty) {
          return const Text(
            '暂无可管理的词书。',
            style: TextStyle(color: ReciteColors.muted),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('词书管理', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in stats)
                  _WordBookStatsTile(
                    stats: item,
                    selected: item.book.key == selectedBookKey,
                    onSelect: () => onSelect(item.book.key),
                    onToggle: (enabled) => onToggle(item.book.key, enabled),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _WordBookStatsTile extends StatelessWidget {
  const _WordBookStatsTile({
    required this.stats,
    required this.selected,
    required this.onSelect,
    required this.onToggle,
  });

  final WordBookStats stats;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? ReciteColors.blue : ReciteColors.line;
    final backgroundColor = selected
        ? ReciteColors.blue.withValues(alpha: 0.06)
        : Colors.white;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stats.book.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Switch(
                    value: stats.enabled,
                    onChanged: onToggle,
                    thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Icon(Icons.check_rounded, size: 16);
                      }
                      return const Icon(Icons.pause_rounded, size: 16);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stats.book.description,
                style: const TextStyle(color: ReciteColors.muted),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: stats.progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: ReciteColors.line,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatPill('总量', stats.totalDictionaryWords),
                  _StatPill('已导入', stats.importedWords),
                  _StatPill('剩余', stats.remainingWords),
                  _StatPill('新词', stats.newWords),
                  _StatPill('学习中', stats.learningWords),
                  _StatPill('熟悉', stats.familiarWords),
                  _StatPill('掌握', stats.masteredWords),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    stats.enabled
                        ? Icons.play_circle_rounded
                        : Icons.pause_circle_rounded,
                    size: 18,
                    color: stats.enabled
                        ? ReciteColors.teal
                        : ReciteColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      stats.enabled ? '已启用，会进入学新词抽取' : '已暂停，不再抽取新词',
                      style: const TextStyle(color: ReciteColors.muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ReciteColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ReciteColors.line),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: ReciteColors.ink,
        ),
      ),
    );
  }
}

class _PipelineItem extends StatelessWidget {
  const _PipelineItem(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: ReciteColors.teal,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
