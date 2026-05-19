import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
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
  final _scrollController = ScrollController(keepScrollOffset: false);
  String _query = '';
  LibraryFilter _filter = LibraryFilter.all;
  LibrarySort _sort = LibrarySort.addedDesc;
  final Set<String> _selectedIds = {};
  bool _isDictionaryFilling = false;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
          scrollKey: const PageStorageKey<String>('library-scroll'),
          scrollController: _scrollController,
          title: '我的词库',
          subtitle: _selectionMode
              ? '已选择 ${_selectedIds.length} 个单词'
              : '搜索、筛选、编辑自己的 GRE 单词资产',
          action: _selectionMode
              ? _SelectionActions(
                  selectedCount: _selectedIds.length,
                  isDictionaryFilling: _isDictionaryFilling,
                  onDictionaryFill: () => _fillSelectedFromDictionary(store),
                  onQueueAi: () => _queueSelectedForAi(store),
                  onDelete: () => _deleteSelected(store, context),
                  onCancel: () => setState(_selectedIds.clear),
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
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (words.isEmpty)
              const SectionCard(child: Text('还没有匹配的单词。'))
            else
              for (final word in words)
                _WordTile(
                  key: ValueKey(word.id),
                  word: word,
                  selected: _selectedIds.contains(word.id),
                  selectionMode: _selectionMode,
                  onLongPress: () =>
                      _preserveScroll(() => _selectedIds.add(word.id)),
                  onSelectionChanged: (selected) {
                    _preserveScroll(() {
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

  void _preserveScroll(VoidCallback update) {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0;
    setState(update);

    void restore() {
      if (!_scrollController.hasClients) {
        return;
      }
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(offset.clamp(0, max).toDouble());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => restore());
    Future<void>.delayed(const Duration(milliseconds: 80), restore);
    Future<void>.delayed(const Duration(milliseconds: 220), restore);
  }

  Future<void> _fillSelectedFromDictionary(AppStore store) async {
    setState(() => _isDictionaryFilling = true);
    final result = await store.fillManyFromDictionary(_selectedIds.toList());
    if (!mounted) {
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
  }

  Future<void> _queueSelectedForAi(AppStore store) async {
    await store.queueManyForAi(_selectedIds.toList());
    if (!mounted) {
      return;
    }
    setState(_selectedIds.clear);
  }

  Future<void> _deleteSelected(AppStore store, BuildContext context) async {
    final confirmed = await _confirmDelete(context);
    if (confirmed != true) {
      return;
    }
    await store.deleteWords(_selectedIds.toList());
    if (!mounted) {
      return;
    }
    setState(_selectedIds.clear);
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

class _SelectionActions extends StatelessWidget {
  const _SelectionActions({
    required this.selectedCount,
    required this.isDictionaryFilling,
    required this.onDictionaryFill,
    required this.onQueueAi,
    required this.onDelete,
    required this.onCancel,
  });

  final int selectedCount;
  final bool isDictionaryFilling;
  final VoidCallback onDictionaryFill;
  final VoidCallback onQueueAi;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Chip(
          avatar: const Icon(Icons.check_rounded, size: 18),
          label: Text('$selectedCount'),
          side: BorderSide.none,
          backgroundColor: ReciteColors.blue.withValues(alpha: 0.1),
        ),
        Tooltip(
          message: isDictionaryFilling ? '词典补全中' : '词典补全',
          child: IconButton.filledTonal(
            onPressed: isDictionaryFilling ? null : onDictionaryFill,
            icon: const Icon(Icons.menu_book_rounded),
          ),
        ),
        Tooltip(
          message: '加入 AI 补全队列',
          child: IconButton.filledTonal(
            onPressed: onQueueAi,
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
        ),
        Tooltip(
          message: '删除选中单词',
          child: IconButton.filled(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_rounded),
          ),
        ),
        Tooltip(
          message: '取消选择',
          child: IconButton.filledTonal(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({
    super.key,
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
    final store = AppScope.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onLongPress: onLongPress,
      onTap: selectionMode
          ? () => onSelectionChanged(!selected)
          : () => showDialog<void>(
              context: context,
              useRootNavigator: false,
              builder: (_) => Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _WordDetailSheet(word: word, store: store),
                ),
              ),
            ),
      child: SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SelectionBox(
              value: selected,
              onChanged: (v) => onSelectionChanged(v),
            ),
            const SizedBox(width: 8),
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

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(top: 2, right: 2, bottom: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: value ? ReciteColors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: value ? ReciteColors.blue : ReciteColors.muted,
              width: 1.8,
            ),
          ),
          child: value
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : null,
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
  const _WordDetailSheet({required this.word, required this.store});

  final WordEntry word;
  final AppStore store;

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
                  if (widget.word.roots.isNotEmpty)
                    Chip(
                      label: Text('词根 ${widget.word.roots.length}'),
                      side: BorderSide.none,
                    ),
                  if (widget.word.example.trim().isNotEmpty)
                    const Chip(label: Text('例句已填'), side: BorderSide.none),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_editing)
              _buildEditFields(context)
            else
              SectionCard(
                padding: const EdgeInsets.all(18),
                child: _buildPreview(context),
              ),
            const SizedBox(height: 12),
            if (_canUseDictionaryFill(widget.word.enrichmentStatus)) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isDictionaryFilling
                      ? null
                      : () async {
                          setState(() => _isDictionaryFilling = true);
                          final filled = await widget.store
                              .fillWordFromDictionary(widget.word.id);
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
                          await widget.store.queueForAi(widget.word.id);
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
                        await widget.store.updateWordContent(
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
    final roots = widget.word.roots;
    final synonyms = _splitPreviewList(_synonymsController.text);
    final antonyms = _splitPreviewList(_antonymsController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasText(_chineseController.text))
          _PreviewBlock(title: '中文释义', child: Text(_chineseController.text)),
        if (_hasText(_englishController.text))
          _PreviewBlock(title: '英文释义', child: Text(_englishController.text)),
        if (_hasText(_greFocusController.text))
          _PreviewBlock(title: 'GRE 考点', child: Text(_greFocusController.text)),
        if (roots.isNotEmpty || _hasText(_rootsController.text))
          _PreviewBlock(
            title: '词根词缀',
            child: roots.isEmpty
                ? Text(_rootsController.text)
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final root in roots)
                        Chip(
                          label: Text('${root.part}: ${root.meaning}'),
                          side: BorderSide.none,
                          backgroundColor: ReciteColors.blue.withValues(
                            alpha: 0.08,
                          ),
                        ),
                    ],
                  ),
          ),
        if (synonyms.isNotEmpty)
          _PreviewBlock(title: '同义词', child: Text(synonyms.join(' / '))),
        if (antonyms.isNotEmpty)
          _PreviewBlock(title: '反义词', child: Text(antonyms.join(' / '))),
        if (_hasText(_exampleController.text))
          _PreviewBlock(title: '例句', child: Text(_exampleController.text)),
        if (_hasText(_memoryTipController.text))
          _PreviewBlock(title: '记忆提示', child: Text(_memoryTipController.text)),
        if (_hasText(_noteController.text))
          _PreviewBlock(title: '个人备注', child: Text(_noteController.text)),
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

class _PreviewBlock extends StatelessWidget {
  const _PreviewBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          child,
        ],
      ),
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

bool _hasText(String value) => value.trim().isNotEmpty;

List<String> _splitPreviewList(String value) {
  return value
      .split(RegExp(r'[,，;；\n/]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
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
