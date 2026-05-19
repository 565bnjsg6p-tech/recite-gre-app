import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/word_entry.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_card.dart';

enum StudyMode { review, newWords }

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  StudyMode _mode = StudyMode.review;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return PageScaffold(
      title: '学习',
      subtitle: '把复习和学新词分开，进度清楚，节奏更稳',
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<StudyMode>(
                segments: const [
                  ButtonSegment(
                    value: StudyMode.review,
                    icon: Icon(Icons.repeat_rounded),
                    label: Text('复习'),
                  ),
                  ButtonSegment(
                    value: StudyMode.newWords,
                    icon: Icon(Icons.auto_stories_rounded),
                    label: Text('学新词'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (value) {
                  setState(() => _mode = value.first);
                },
              ),
              const SizedBox(height: 16),
              IndexedStack(
                index: _mode == StudyMode.review ? 0 : 1,
                children: [
                  StreamBuilder<List<WordEntry>>(
                    stream: store.watchDueWords(),
                    builder: (context, snapshot) {
                      final words = snapshot.data ?? const <WordEntry>[];
                      return _StudyDeck(
                        words: words,
                        modeLabel: '复习',
                        emptyTitle: '本轮到期卡片已清空',
                        emptyHint: '可以去录入页补新词，或切到“学新词”继续推进词书。',
                        isNewStudy: false,
                      );
                    },
                  ),
                  StreamBuilder<List<WordEntry>>(
                    stream: store.watchNewWords(),
                    builder: (context, snapshot) {
                      final words = snapshot.data ?? const <WordEntry>[];
                      return _StudyDeck(
                        words: words,
                        modeLabel: '学新词',
                        emptyTitle: '今天的新词学完了',
                        emptyHint: '词书里的新词已经清掉，换个词书或明天再继续。',
                        isNewStudy: true,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudyDeck extends StatefulWidget {
  const _StudyDeck({
    required this.words,
    required this.modeLabel,
    required this.emptyTitle,
    required this.emptyHint,
    required this.isNewStudy,
  });

  final List<WordEntry> words;
  final String modeLabel;
  final String emptyTitle;
  final String emptyHint;
  final bool isNewStudy;

  @override
  State<_StudyDeck> createState() => _StudyDeckState();
}

class _StudyDeckState extends State<_StudyDeck> {
  final List<WordEntry> _sessionWords = [];
  final List<int> _history = [];
  final Map<String, _NewWordProgress> _newWordProgress = {};
  int _current = 0;
  int _completed = 0;
  int _targetTotal = 0;
  int _newWordStep = 0;
  bool _revealed = false;
  bool _isSaving = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    if (widget.words.isNotEmpty) {
      _startSession(widget.words);
    } else {
      _locked = false;
    }
  }

  @override
  void didUpdateWidget(covariant _StudyDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sessionWords.isEmpty && widget.words.isNotEmpty) {
      _startSession(widget.words);
      return;
    }
    if (!_locked && !_sameWords(oldWidget.words, widget.words)) {
      _startSession(widget.words);
      return;
    }
    if (widget.isNewStudy &&
        _completed == 0 &&
        _history.isEmpty &&
        !_revealed &&
        !_sameWords(oldWidget.words, widget.words)) {
      _startSession(widget.words);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionWords.isEmpty) {
      return _EmptyDeck(
        modeLabel: widget.modeLabel,
        title: widget.emptyTitle,
        hint: widget.emptyHint,
        onRefresh: widget.words.isEmpty ? null : () => _startSession(widget.words),
      );
    }

    if (_current >= _sessionWords.length) {
      return _CompleteDeck(
        modeLabel: widget.modeLabel,
        completed: _completed,
        total: _targetTotal,
        onRefresh: () => _startSession(widget.words),
      );
    }

    final word = _sessionWords[_current];
    final total = widget.isNewStudy ? _targetTotal : _sessionWords.length;
    final progress = total == 0 ? 0.0 : (_completed / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressHeader(
          label: widget.modeLabel,
          completed: _completed,
          total: total,
          progress: progress,
          onBack: _history.isEmpty ? null : _goBack,
          hint: widget.isNewStudy
              ? '首次就认识会直接毕业；不熟练会在本轮间隔出现，直到稳定认识。'
              : '复习由到期日和熟练度自动生成。每次评分都会更新下次出现时间。',
        ),
        const SizedBox(height: 12),
        SectionCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(
                      widget.isNewStudy
                          ? '${_completed + 1}/$total'
                          : '${_current + 1}/${_sessionWords.length}',
                    ),
                    side: BorderSide.none,
                    backgroundColor: ReciteColors.teal.withValues(alpha: 0.12),
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
        if (_revealed) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => _saveReview(word, ReviewRating.forgot),
                  child: const Text('不认识'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => _saveReview(word, ReviewRating.shaky),
                  child: const Text('模糊'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () => _saveReview(word, ReviewRating.known),
                  child: const Text('认识'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _startSession(List<WordEntry> words) {
    setState(() {
      _sessionWords
        ..clear()
        ..addAll(words);
      _history.clear();
      _newWordProgress.clear();
      _current = 0;
      _completed = 0;
      _targetTotal = words.length;
      _newWordStep = 0;
      _revealed = false;
      _isSaving = false;
      _locked = true;
    });
  }

  bool _sameWords(List<WordEntry> a, List<WordEntry> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) {
        return false;
      }
    }
    return true;
  }

  void _goBack() {
    if (_history.isEmpty) {
      return;
    }
    setState(() {
      _current = _history.removeLast();
      _revealed = false;
    });
  }

  Future<void> _saveReview(WordEntry word, ReviewRating rating) async {
    if (widget.isNewStudy) {
      await _saveNewWordReview(word, rating);
      return;
    }
    setState(() => _isSaving = true);
    await AppScope.of(context).recordReview(
      word,
      rating,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _revealed = false;
      _completed += 1;
      if (_current < _sessionWords.length - 1) {
        _history.add(_current);
        _current += 1;
      } else {
        _current = _sessionWords.length;
      }
    });
  }

  Future<void> _saveNewWordReview(WordEntry word, ReviewRating rating) async {
    setState(() => _isSaving = true);
    final progress = _newWordProgress.putIfAbsent(
      word.id,
      _NewWordProgress.new,
    );
    progress.attempts += 1;
    _newWordStep += 1;

    final firstSightKnown =
        rating == ReviewRating.known && progress.attempts == 1;
    var mastered = firstSightKnown;
    if (!mastered) {
      if (rating == ReviewRating.known) {
        final lastKnownStep = progress.lastKnownStep;
        if (lastKnownStep == null || _newWordStep - lastKnownStep > 1) {
          progress.spacedKnownHits += 1;
        }
        progress.lastKnownStep = _newWordStep;
        mastered = progress.spacedKnownHits >= 2;
      } else {
        progress.spacedKnownHits = 0;
        progress.lastKnownStep = null;
      }
    }

    if (mastered) {
      await AppScope.of(context).completeNewWord(
        word,
        firstSightKnown: firstSightKnown,
      );
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _revealed = false;
      if (mastered) {
        _completed += 1;
        _removeFutureCopies(word.id);
      } else {
        _requeueCurrentWord(word, rating);
      }
      if (_completed >= _targetTotal) {
        _current = _sessionWords.length;
        return;
      }
      if (_current < _sessionWords.length - 1) {
        _history.add(_current);
        _current += 1;
      } else {
        _current = _sessionWords.length;
      }
    });
  }

  void _requeueCurrentWord(WordEntry word, ReviewRating rating) {
    final gap = switch (rating) {
      ReviewRating.forgot => 2,
      ReviewRating.shaky => 3,
      ReviewRating.known => 4,
    };
    final insertAt = (_current + 1 + gap).clamp(
      _current + 1,
      _sessionWords.length,
    );
    _sessionWords.insert(insertAt, word);
  }

  void _removeFutureCopies(String wordId) {
    for (var i = _sessionWords.length - 1; i > _current; i--) {
      if (_sessionWords[i].id == wordId) {
        _sessionWords.removeAt(i);
      }
    }
  }
}

class _NewWordProgress {
  int attempts = 0;
  int spacedKnownHits = 0;
  int? lastKnownStep;
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.label,
    required this.completed,
    required this.total,
    required this.progress,
    required this.onBack,
    this.hint,
  });

  final String label;
  final int completed;
  final int total;
  final double progress;
  final VoidCallback? onBack;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text('$completed / $total'),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '返回上一词',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : progress,
            minHeight: 8,
            backgroundColor: ReciteColors.line,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint!,
            style: const TextStyle(color: ReciteColors.muted),
          ),
        ],
      ],
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({
    required this.modeLabel,
    required this.title,
    required this.hint,
    required this.onRefresh,
  });

  final String modeLabel;
  final String title;
  final String hint;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressHeader(
          label: modeLabel,
          completed: 0,
          total: 0,
          progress: 0,
          onBack: null,
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(hint),
              if (onRefresh != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重新加载队列'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CompleteDeck extends StatelessWidget {
  const _CompleteDeck({
    required this.modeLabel,
    required this.completed,
    required this.total,
    required this.onRefresh,
  });

  final String modeLabel;
  final int completed;
  final int total;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressHeader(
          label: modeLabel,
          completed: completed,
          total: total,
          progress: total == 0 ? 0 : 1,
          onBack: null,
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本轮完成',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text('这轮已经完成 $completed 张卡片。'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重新加载队列'),
              ),
            ],
          ),
        ),
      ],
    );
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
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            Chip(
              label: Text(word.sourceLabel),
              side: BorderSide.none,
              backgroundColor: word.isBookWord
                  ? ReciteColors.teal.withValues(alpha: 0.12)
                  : ReciteColors.blue.withValues(alpha: 0.08),
            ),
            if (word.bookKey.isNotEmpty)
              Chip(
                label: Text(word.bookKey.toUpperCase()),
                side: BorderSide.none,
                backgroundColor: ReciteColors.orange.withValues(alpha: 0.12),
              ),
          ],
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
