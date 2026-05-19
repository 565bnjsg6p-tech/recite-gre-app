import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/word_entry.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_card.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool _revealed = false;
  int _current = 0;
  int _completed = 0;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return StreamBuilder<List<WordEntry>>(
      stream: store.watchDueWords(),
      builder: (context, snapshot) {
        final words = snapshot.data ?? const <WordEntry>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PageScaffold(
            title: 'Anki 复习',
            subtitle: '先回忆，再看解释',
            children: [Center(child: CircularProgressIndicator())],
          );
        }
        if (words.isEmpty) {
          return PageScaffold(
            title: '复习完成',
            subtitle: '今天完成 $_completed 张卡片',
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本轮到期卡片已清空',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('可以去录入页添加新词，或在词库里把词典补全的单词升级为 AI 补全。'),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => setState(() => _completed = 0),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('刷新复习列表'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (_current >= words.length) {
          _current = 0;
        }
        final word = words[_current];

        return PageScaffold(
          title: 'Anki 复习',
          subtitle: '今日已完成 $_completed 张',
          children: [
            SectionCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text('${_current + 1}/${words.length}'),
                        side: BorderSide.none,
                        backgroundColor: ReciteColors.teal.withValues(
                          alpha: 0.12,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: '发音',
                        onPressed: () {},
                        icon: const Icon(Icons.volume_up_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) {
                      final scale = Tween<double>(begin: 0.96, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: scale, child: child),
                      );
                    },
                    child: _revealed
                        ? _AnswerContent(
                            key: ValueKey('answer-${word.id}'),
                            word: word,
                          )
                        : _QuestionContent(
                            key: ValueKey('question-${word.id}'),
                            word: word,
                          ),
                  ),
                  const SizedBox(height: 24),
                  if (!_revealed)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _revealed = true),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('显示答案'),
                      ),
                    ),
                ],
              ),
            ),
            if (_revealed)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _saveReview(
                              store,
                              word,
                              ReviewRating.forgot,
                              words.length,
                            ),
                      child: const Text('不认识'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _saveReview(
                              store,
                              word,
                              ReviewRating.shaky,
                              words.length,
                            ),
                      child: const Text('模糊'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () => _saveReview(
                              store,
                              word,
                              ReviewRating.known,
                              words.length,
                            ),
                      child: const Text('认识'),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Future<void> _saveReview(
    AppStore store,
    WordEntry word,
    ReviewRating rating,
    int wordCount,
  ) async {
    setState(() => _isSaving = true);
    await store.recordReview(word, rating);
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _revealed = false;
      _completed += 1;
      _current = rating == ReviewRating.forgot
          ? 0
          : (wordCount <= 1 ? 0 : _current % (wordCount - 1));
    });
  }
}

class _QuestionContent extends StatelessWidget {
  const _QuestionContent({super.key, required this.word});

  final WordEntry word;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        word.word,
        style: Theme.of(
          context,
        ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AnswerContent extends StatelessWidget {
  const _AnswerContent({super.key, required this.word});

  final WordEntry word;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(word.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            word.word,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 18),
        if (_hasText(word.chineseMeaning))
          _AnswerBlock(title: '中文释义', child: Text(word.chineseMeaning)),
        if (_hasText(word.englishMeaning))
          _AnswerBlock(title: '英文释义', child: Text(word.englishMeaning)),
        if (_hasText(word.greFocus))
          _AnswerBlock(title: 'GRE 考点', child: Text(word.greFocus)),
        if (word.roots.isNotEmpty)
          _AnswerBlock(
            title: '词根词缀',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final root in word.roots)
                  Chip(
                    label: Text('${root.part}: ${root.meaning}'),
                    side: BorderSide.none,
                    backgroundColor: ReciteColors.blue.withValues(alpha: 0.08),
                  ),
              ],
            ),
          ),
        if (_hasList(word.synonyms))
          _AnswerBlock(title: '同义词', child: Text(_joinList(word.synonyms))),
        if (_hasList(word.antonyms))
          _AnswerBlock(title: '反义词', child: Text(_joinList(word.antonyms))),
        if (_hasText(word.example))
          _AnswerBlock(title: '例句', child: Text(word.example)),
        if (_hasText(word.memoryTip))
          _AnswerBlock(title: '记忆提示', child: Text(word.memoryTip)),
        if (word.note.trim().isNotEmpty)
          _AnswerBlock(title: '个人备注', child: Text(word.note.trim())),
      ],
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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

bool _hasText(String value) => value.trim().isNotEmpty;

bool _hasList(List<String> values) =>
    values.any((item) => item.trim().isNotEmpty);

String _joinList(List<String> values) {
  return values
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .join(' / ');
}
