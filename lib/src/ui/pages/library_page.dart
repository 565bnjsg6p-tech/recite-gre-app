import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/word_entry.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_card.dart';

enum LibraryFilter { all, due, dictionary, ai, queued, confusing, highFreq }

enum LibrarySort { addedDesc, alphaAsc, masteryAsc }

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _query = '';
  LibraryFilter _filter = LibraryFilter.all;
  LibrarySort _sort = LibrarySort.addedDesc;
  final Set<String> _selectedIds = {};
  bool _isDictionaryFilling = false;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return StreamBuilder<List<WordEntry>>(
      stream: store.watchWords(),
      builder: (context, snapshot) {
        final allWords = snapshot.data ?? const <WordEntry>[];
        final words =
            allWords
                .where(
                  (item) =>
                      item.word.toLowerCase().contains(_query.toLowerCase()),
                )
                .where(_matchesFilter)
                .toList()
              ..sort(_compareWords);

        return PageScaffold(
          title: '我的词库',
          subtitle: _selectionMode
              ? '已选择 ${_selectedIds.length} 个单词'
              : '搜索、筛选、编辑自己的 GRE 单词资产',
          action: _selectionMode
              ? IconButton.filledTonal(
                  tooltip: '取消选择',
                  onPressed: () => setState(_selectedIds.clear),
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                labelText: '搜索单词',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 920;
                final filterBar = _FilterBar(
                  allWords: allWords,
                  selected: _filter,
                  onSelected: (filter) => setState(() => _filter = filter),
                );
                final sortPicker = _SortPicker(
                  value: _sort,
                  onChanged: (value) => setState(() => _sort = value),
                );
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: filterBar),
                          const SizedBox(width: 12),
                          SizedBox(width: 220, child: sortPicker),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          filterBar,
                          const SizedBox(height: 12),
                          sortPicker,
                        ],
                      );
              },
            ),
            if (_selectionMode) ...[
              const SizedBox(height: 14),
              _BatchActions(
                selectedCount: _selectedIds.length,
                isDictionaryFilling: _isDictionaryFilling,
                onDictionaryFill: () async {
                  setState(() => _isDictionaryFilling = true);
                  final result = await store.fillManyFromDictionary(
                    _selectedIds.toList(),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  setState(() {
                    _isDictionaryFilling = false;
                    if (result.filled > 0) {
                      _selectedIds.clear();
                    }
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result.message)));
                },
                onQueueAi: () async {
                  await store.queueManyForAi(_selectedIds.toList());
                  setState(_selectedIds.clear);
                },
                onDelete: () async {
                  final confirmed = await _confirmDelete(context);
                  if (confirmed != true) {
                    return;
                  }
                  await store.deleteWords(_selectedIds.toList());
                  setState(_selectedIds.clear);
                },
              ),
            ],
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (words.isEmpty)
              const SectionCard(child: Text('还没有匹配的单词。'))
            else
              for (final word in words)
                _WordTile(
                  word: word,
                  selected: _selectedIds.contains(word.id),
                  selectionMode: _selectionMode,
                  onLongPress: () => setState(() => _selectedIds.add(word.id)),
                  onSelectionChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedIds.add(word.id);
                      } else {
                        _selectedIds.remove(word.id);
                      }
                    });
                  },
                ),
          ],
        );
      },
    );
  }

  bool _matchesFilter(WordEntry word) {
    switch (_filter) {
      case LibraryFilter.all:
        return true;
      case LibraryFilter.due:
        return word.dueLabel == '今天';
      case LibraryFilter.dictionary:
        return word.enrichmentStatus == 'dictionary';
      case LibraryFilter.ai:
        return word.enrichmentStatus == 'ai';
      case LibraryFilter.queued:
        return word.enrichmentStatus == 'queued' ||
            word.enrichmentStatus == 'queued_ai';
      case LibraryFilter.confusing:
        return word.tags.any((tag) => tag.contains('易混'));
      case LibraryFilter.highFreq:
        return word.tags.any((tag) => tag.contains('高频'));
    }
  }

  int _compareWords(WordEntry a, WordEntry b) {
    switch (_sort) {
      case LibrarySort.addedDesc:
        final created = b.createdAtMs.compareTo(a.createdAtMs);
        if (created != 0) {
          return created;
        }
        return a.word.compareTo(b.word);
      case LibrarySort.alphaAsc:
        return a.word.compareTo(b.word);
      case LibrarySort.masteryAsc:
        final mastery = a.mastery.index.compareTo(b.mastery.index);
        if (mastery != 0) {
          return mastery;
        }
        final dueCompare = a.dueLabel.compareTo(b.dueLabel);
        if (dueCompare != 0) {
          return dueCompare;
        }
        final created = b.createdAtMs.compareTo(a.createdAtMs);
        if (created != 0) {
          return created;
        }
        return a.word.compareTo(b.word);
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除选中单词？'),
        content: const Text('删除后会同时移除这些单词的复习记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.allWords,
    required this.selected,
    required this.onSelected,
  });

  final List<WordEntry> allWords;
  final LibraryFilter selected;
  final ValueChanged<LibraryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: '全部 ${allWords.length}',
          selected: selected == LibraryFilter.all,
          onSelected: () => onSelected(LibraryFilter.all),
        ),
        _FilterChip(
          label: '今天到期 ${allWords.where((w) => w.dueLabel == '今天').length}',
          selected: selected == LibraryFilter.due,
          onSelected: () => onSelected(LibraryFilter.due),
        ),
        _FilterChip(
          label:
              '词典补全 ${allWords.where((w) => w.enrichmentStatus == 'dictionary').length}',
          selected: selected == LibraryFilter.dictionary,
          onSelected: () => onSelected(LibraryFilter.dictionary),
        ),
        _FilterChip(
          label:
              'AI 补全 ${allWords.where((w) => w.enrichmentStatus == 'ai').length}',
          selected: selected == LibraryFilter.ai,
          onSelected: () => onSelected(LibraryFilter.ai),
        ),
        _FilterChip(
          label:
              '待补全 ${allWords.where((w) => w.enrichmentStatus == 'queued' || w.enrichmentStatus == 'queued_ai').length}',
          selected: selected == LibraryFilter.queued,
          onSelected: () => onSelected(LibraryFilter.queued),
        ),
        _FilterChip(
          label:
              '易混 ${allWords.where((w) => w.tags.any((tag) => tag.contains('易混'))).length}',
          selected: selected == LibraryFilter.confusing,
          onSelected: () => onSelected(LibraryFilter.confusing),
        ),
        _FilterChip(
          label:
              '高频 ${allWords.where((w) => w.tags.any((tag) => tag.contains('高频'))).length}',
          selected: selected == LibraryFilter.highFreq,
          onSelected: () => onSelected(LibraryFilter.highFreq),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _BatchActions extends StatelessWidget {
  const _BatchActions({
    required this.selectedCount,
    required this.isDictionaryFilling,
    required this.onDictionaryFill,
    required this.onQueueAi,
    required this.onDelete,
  });

  final int selectedCount;
  final bool isDictionaryFilling;
  final VoidCallback onDictionaryFill;
  final VoidCallback onQueueAi;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('已选择 $selectedCount 个'),
          ),
          OutlinedButton.icon(
            onPressed: isDictionaryFilling ? null : onDictionaryFill,
            icon: const Icon(Icons.menu_book_rounded),
            label: Text(isDictionaryFilling ? '补全中' : '词典补全'),
          ),
          OutlinedButton.icon(
            onPressed: onQueueAi,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('加入 AI'),
          ),
          FilledButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_rounded),
            label: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.word,
    required this.selected,
    required this.selectionMode,
    required this.onLongPress,
    required this.onSelectionChanged,
  });

  final WordEntry word;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final displayTags = _displayTags(word);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onLongPress: onLongPress,
      onTap: selectionMode
          ? () => onSelectionChanged(!selected)
          : () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _WordDetailSheet(word: word),
            ),
      child: SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectionMode) ...[
              Checkbox(
                value: selected,
                onChanged: (v) => onSelectionChanged(v ?? false),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          word.word,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        word.dueLabel,
                        style: const TextStyle(color: ReciteColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(word.chineseMeaning),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(statusLabel(word.enrichmentStatus)),
                        side: BorderSide.none,
                        backgroundColor: statusColor(
                          word.enrichmentStatus,
                        ).withValues(alpha: 0.12),
                      ),
                      for (final tag in displayTags.take(5))
                        Chip(
                          label: Text(tag),
                          side: BorderSide.none,
                          backgroundColor: ReciteColors.blue.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      Chip(
                        label: Text(masteryLabel(word.mastery)),
                        side: BorderSide.none,
                        backgroundColor: ReciteColors.orange.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    word.greFocus,
                    style: const TextStyle(color: ReciteColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _displayTags(WordEntry word) {
  final hiddenStatusLabel = statusLabel(word.enrichmentStatus);
  final seen = <String>{};
  return word.tags.where((tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || trimmed == hiddenStatusLabel) {
      return false;
    }
    return seen.add(trimmed);
  }).toList();
}

class _WordDetailSheet extends StatefulWidget {
  const _WordDetailSheet({required this.word});

  final WordEntry word;

  @override
  State<_WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<_WordDetailSheet> {
  late final TextEditingController _chineseController;
  late final TextEditingController _englishController;
  late final TextEditingController _greFocusController;
  late final TextEditingController _rootsController;
  late final TextEditingController _synonymsController;
  late final TextEditingController _antonymsController;
  late final TextEditingController _exampleController;
  late final TextEditingController _memoryTipController;
  late final TextEditingController _noteController;
  late final TextEditingController _tagsController;
  bool _isSaving = false;
  bool _isQueueing = false;
  bool _isDictionaryFilling = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final word = widget.word;
    _chineseController = TextEditingController(text: word.chineseMeaning);
    _englishController = TextEditingController(text: word.englishMeaning);
    _greFocusController = TextEditingController(text: word.greFocus);
    _rootsController = TextEditingController(
      text: word.roots
          .map((root) => '${root.part}: ${root.meaning}')
          .join('\n'),
    );
    _synonymsController = TextEditingController(text: word.synonyms.join(', '));
    _antonymsController = TextEditingController(text: word.antonyms.join(', '));
    _exampleController = TextEditingController(text: word.example);
    _memoryTipController = TextEditingController(text: word.memoryTip);
    _noteController = TextEditingController(text: word.note);
    _tagsController = TextEditingController(text: word.tags.join(', '));
  }

  @override
  void dispose() {
    _chineseController.dispose();
    _englishController.dispose();
    _greFocusController.dispose();
    _rootsController.dispose();
    _synonymsController.dispose();
    _antonymsController.dispose();
    _exampleController.dispose();
    _memoryTipController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final store = AppScope.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 18, 24, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.word.word,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _editing ? '预览' : '编辑',
                  onPressed: () => setState(() => _editing = !_editing),
                  icon: Icon(
                    _editing ? Icons.visibility_rounded : Icons.edit_rounded,
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(statusLabel(widget.word.enrichmentStatus)),
              side: BorderSide.none,
              backgroundColor: statusColor(
                widget.word.enrichmentStatus,
              ).withValues(alpha: 0.12),
            ),
            const SizedBox(height: 12),
            SectionCard(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(widget.word.dueLabel),
                    side: BorderSide.none,
                    backgroundColor: ReciteColors.blue.withValues(alpha: 0.1),
                  ),
                  Chip(
                    label: Text(masteryLabel(widget.word.mastery)),
                    side: BorderSide.none,
                    backgroundColor: ReciteColors.orange.withValues(
                      alpha: 0.12,
                    ),
                  ),
                  Chip(
                    label: Text(_formatCreatedAt(widget.word.createdAtMs)),
                    side: BorderSide.none,
                    backgroundColor: ReciteColors.teal.withValues(alpha: 0.12),
                  ),
                  Chip(
                    label: Text('词根 ${widget.word.roots.length}'),
                    side: BorderSide.none,
                  ),
                  Chip(
                    label: Text(
                      '例句 ${widget.word.example.isEmpty ? '暂无' : '已填'}',
                    ),
                    side: BorderSide.none,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_editing) _buildEditFields(context) else _buildPreview(context),
            const SizedBox(height: 12),
            if (_canUseDictionaryFill(widget.word.enrichmentStatus)) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isDictionaryFilling
                      ? null
                      : () async {
                          setState(() => _isDictionaryFilling = true);
                          final filled = await store.fillWordFromDictionary(
                            widget.word.id,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          if (filled) {
                            Navigator.pop(context);
                          } else {
                            setState(() => _isDictionaryFilling = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '基础词典里没有命中 ${widget.word.word}，可以加入 AI 队列。',
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(_isDictionaryFilling ? '补全中' : '用基础词典补全'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (widget.word.enrichmentStatus != 'ai' &&
                widget.word.enrichmentStatus != 'queued_ai')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isQueueing
                      ? null
                      : () async {
                          setState(() => _isQueueing = true);
                          await store.queueForAi(widget.word.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(_isQueueing ? '加入中' : '升级为 AI 补全'),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        await store.updateWordContent(
                          original: widget.word,
                          chineseMeaning: _chineseController.text,
                          englishMeaning: _englishController.text,
                          greFocus: _greFocusController.text,
                          rootsText: _rootsController.text,
                          synonymsText: _synonymsController.text,
                          antonymsText: _antonymsController.text,
                          example: _exampleController.text,
                          memoryTip: _memoryTipController.text,
                          note: _noteController.text,
                          tagsText: _tagsController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                icon: const Icon(Icons.save_rounded),
                label: Text(_isSaving ? '保存中' : '保存修改'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_textOrPlaceholder(_chineseController.text)),
        const SizedBox(height: 12),
        Text(_textOrPlaceholder(_englishController.text)),
        const Divider(height: 28),
        Text('GRE 考点', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(_textOrPlaceholder(_greFocusController.text)),
        const SizedBox(height: 16),
        Text('词根词缀', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(_textOrPlaceholder(_rootsController.text)),
        const SizedBox(height: 16),
        Text('同反义词', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('同义词：${_textOrPlaceholder(_synonymsController.text)}'),
        const SizedBox(height: 4),
        Text('反义词：${_textOrPlaceholder(_antonymsController.text)}'),
        const SizedBox(height: 16),
        Text('例句', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(_textOrPlaceholder(_exampleController.text)),
        const SizedBox(height: 16),
        Text('记忆提示', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(_textOrPlaceholder(_memoryTipController.text)),
        const SizedBox(height: 16),
        Text('个人备注', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(_textOrPlaceholder(_noteController.text)),
      ],
    );
  }

  Widget _buildEditFields(BuildContext context) {
    return Column(
      children: [
        _EditField(label: '中文释义', controller: _chineseController, minLines: 2),
        _EditField(label: '英文释义', controller: _englishController, minLines: 2),
        _EditField(
          label: 'GRE 考点',
          controller: _greFocusController,
          minLines: 3,
        ),
        _EditField(
          label: '词根词缀（一行一个，part: meaning）',
          controller: _rootsController,
          minLines: 3,
        ),
        _EditField(label: '同义词（逗号分隔）', controller: _synonymsController),
        _EditField(label: '反义词（逗号分隔）', controller: _antonymsController),
        _EditField(label: '例句', controller: _exampleController, minLines: 2),
        _EditField(
          label: '记忆提示',
          controller: _memoryTipController,
          minLines: 2,
        ),
        _EditField(label: '个人备注', controller: _noteController, minLines: 3),
        _EditField(label: '标签（逗号分隔）', controller: _tagsController),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.minLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines + 3,
        decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
      ),
    );
  }
}

String _textOrPlaceholder(String value, [String placeholder = '暂无']) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? placeholder : trimmed;
}

String masteryLabel(MasteryLevel level) {
  switch (level) {
    case MasteryLevel.newWord:
      return '未学';
    case MasteryLevel.learning:
      return '学习中';
    case MasteryLevel.familiar:
      return '熟悉';
    case MasteryLevel.mastered:
      return '掌握';
  }
}

String statusLabel(String status) {
  switch (status) {
    case 'dictionary':
      return '词典补全';
    case 'ai':
      return 'AI 补全';
    case 'queued_ai':
      return '待 AI 补全';
    case 'failed':
      return '补全失败';
    case 'ready':
      return '示例词条';
    default:
      return '待补全';
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'dictionary':
      return ReciteColors.teal;
    case 'ai':
      return ReciteColors.blue;
    case 'queued_ai':
      return ReciteColors.orange;
    case 'failed':
      return ReciteColors.red;
    default:
      return ReciteColors.muted;
  }
}

bool _canUseDictionaryFill(String status) {
  return status == 'queued' || status == 'queued_ai' || status == 'failed';
}

String _formatCreatedAt(int createdAtMs) {
  final local = DateTime.fromMillisecondsSinceEpoch(createdAtMs).toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}.$month.$day';
}

class _SortPicker extends StatelessWidget {
  const _SortPicker({required this.value, required this.onChanged});

  final LibrarySort value;
  final ValueChanged<LibrarySort> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<LibrarySort>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: '排序',
        prefixIcon: Icon(Icons.sort_rounded),
      ),
      items: const [
        DropdownMenuItem(value: LibrarySort.addedDesc, child: Text('最新添加')),
        DropdownMenuItem(value: LibrarySort.alphaAsc, child: Text('字母顺序')),
        DropdownMenuItem(value: LibrarySort.masteryAsc, child: Text('熟练度优先')),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
