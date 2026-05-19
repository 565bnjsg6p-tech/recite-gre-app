import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
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
  bool _isImporting = false;

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
              const _PipelineItem('AI 队列：先标记为待 AI 补全，下一阶段接 OpenAI 后一键生成深度卡片'),
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
