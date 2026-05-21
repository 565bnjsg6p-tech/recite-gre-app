import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/word_entry.dart';
import '../../theme/app_theme.dart';
import '../../utils/speak_word.dart';
import '../widgets/pronunciation_button.dart';
import '../widgets/section_card.dart';

enum StudyMode { review, newWords, difficult }

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    this.initialMode = StudyMode.review,
    this.initialBookKey,
    this.initialBookLabel,
  });

  final StudyMode initialMode;
  final String? initialBookKey;
  final String? initialBookLabel;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late StudyMode _mode = widget.initialMode;
  String? _bookKey;
  String? _bookLabel;

  @override
  void initState() {
    super.initState();
    _bookKey = widget.initialBookKey;
    _bookLabel = widget.initialBookLabel;
  }

  @override
  void didUpdateWidget(covariant ReviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode ||
        oldWidget.initialBookKey != widget.initialBookKey ||
        oldWidget.initialBookLabel != widget.initialBookLabel) {
      setState(() {
        _mode = widget.initialMode;
        _bookKey = widget.initialBookKey;
        _bookLabel = widget.initialBookLabel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final horizontalPadding = compact ? 10.0 : 24.0;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              compact ? 8 : 14,
              horizontalPadding,
              8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StudyModeSelector(
                  value: _mode,
                  onChanged: (value) => setState(() => _mode = value),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: IndexedStack(
                    index: _mode.index,
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
                        stream: store.watchNewWords(bookKey: _bookKey),
                        builder: (context, snapshot) {
                          final words = snapshot.data ?? const <WordEntry>[];
                          final modeLabel = _bookLabel == null
                              ? '学新词'
                              : '学新词 · $_bookLabel';
                          return _StudyDeck(
                            words: words,
                            modeLabel: modeLabel,
                            emptyTitle: _bookLabel == null
                                ? '今天的新词学完了'
                                : '$_bookLabel 的新词学完了',
                            emptyHint: _bookLabel == null
                                ? '词书里的新词已经清掉，换个词书或明天再继续。'
                                : '这本书当前没有可学新词，可以导入更多词或切回全部词书。',
                            isNewStudy: true,
                          );
                        },
                      ),
                      StreamBuilder<List<WordEntry>>(
                        stream: store.watchDifficultWords(),
                        builder: (context, snapshot) {
                          final words = snapshot.data ?? const <WordEntry>[];
                          return _StudyDeck(
                            words: words,
                            modeLabel: '困难词',
                            emptyTitle: '暂时没有困难词',
                            emptyHint: '当单词出现遗忘、模糊或易度降低时，会自动进入这里集中练习。',
                            isNewStudy: false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
  final FocusNode _focusNode = FocusNode(debugLabel: 'study-deck');
  final List<WordEntry> _sessionWords = [];
  final List<int> _history = [];
  final Map<String, _NewWordProgress> _newWordProgress = {};
  final Map<String, _StudyWordStat> _wordStats = {};
  final Set<String> _sessionDifficultWordIds = {};
  int _current = 0;
  int _completed = 0;
  int _targetTotal = 0;
  int _newWordStep = 0;
  bool _revealed = false;
  bool _isSaving = false;
  bool _locked = false;
  String _feedbackText = '';
  Color _feedbackColor = ReciteColors.teal;

  @override
  void initState() {
    super.initState();
    if (widget.words.isNotEmpty) {
      _startSession(widget.words);
    } else {
      _locked = false;
    }
    _requestKeyboardFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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
        onRefresh: widget.words.isEmpty
            ? null
            : () => _startSession(widget.words),
      );
    }

    if (_current >= _sessionWords.length) {
      return _CompleteDeck(
        modeLabel: widget.modeLabel,
        completed: _completed,
        total: _targetTotal,
        isNewStudy: widget.isNewStudy,
        summary: _buildSummary(),
        onRefresh: () => _startSession(widget.words),
      );
    }

    final word = _sessionWords[_current];
    final total = widget.isNewStudy ? _targetTotal : _sessionWords.length;
    final progress = total == 0 ? 0.0 : (_completed / total).clamp(0.0, 1.0);

    _requestKeyboardFocus();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event, word),
      child: CallbackShortcuts(
        bindings: _shortcutBindings(word),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;
            final rightRailWidth = compact ? 68.0 : 126.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProgressHeader(
                  label: widget.modeLabel,
                  completed: _completed,
                  total: total,
                  progress: progress,
                  onBack: _history.isEmpty ? null : _goBack,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(compact ? 12 : 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ReciteColors.line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
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
                                    backgroundColor: ReciteColors.teal
                                        .withValues(alpha: 0.12),
                                  ),
                                  const Spacer(),
                                  PronunciationButton(word: word.word),
                                ],
                              ),
                              SizedBox(height: compact ? 8 : 14),
                              Expanded(
                                child: RepaintBoundary(
                                  child: AnimatedSwitcher(
                                    duration: _revealed
                                        ? const Duration(milliseconds: 220)
                                        : Duration.zero,
                                    reverseDuration: Duration.zero,
                                    layoutBuilder:
                                        (currentChild, previousChildren) {
                                          return currentChild ??
                                              const SizedBox.shrink();
                                        },
                                    transitionBuilder: (child, animation) {
                                      if (!_revealed) {
                                        return child;
                                      }
                                      return _FlipTransition(
                                        animation: animation,
                                        child: child,
                                      );
                                    },
                                    child: _revealed
                                        ? SingleChildScrollView(
                                            key: ValueKey('answer-${word.id}'),
                                            physics:
                                                const ClampingScrollPhysics(),
                                            child: _AnswerContent(
                                              word: word,
                                              compact: compact,
                                            ),
                                          )
                                        : _QuestionContent(
                                            key: ValueKey(
                                              'question-${word.id}',
                                            ),
                                            word: word,
                                            compact: compact,
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                child: _FeedbackBanner(
                                  text: _feedbackText,
                                  color: _feedbackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 16),
                        SizedBox(
                          width: rightRailWidth,
                          child: _StudyActionRail(
                            revealed: _revealed,
                            isSaving: _isSaving,
                            onReveal: () => setState(() => _revealed = true),
                            onForgot: () =>
                                _saveReview(word, ReviewRating.forgot),
                            onShaky: () =>
                                _saveReview(word, ReviewRating.shaky),
                            onKnown: () =>
                                _saveReview(word, ReviewRating.known),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _requestKeyboardFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _handleKeyEvent(KeyEvent event, WordEntry word) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      if (!_revealed) {
        setState(() => _revealed = true);
      }
      return;
    }
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.arrowLeft) {
      _goBack();
      return;
    }
    if (!_revealed || _isSaving) {
      return;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.digit3) {
      _saveReview(word, ReviewRating.known);
      return;
    }
    if (key == LogicalKeyboardKey.semicolon ||
        key == LogicalKeyboardKey.digit1) {
      _saveReview(word, ReviewRating.forgot);
      return;
    }
    if (key == LogicalKeyboardKey.quote || key == LogicalKeyboardKey.digit2) {
      _saveReview(word, ReviewRating.shaky);
    }
  }

  void _startSession(List<WordEntry> words) {
    setState(() {
      _sessionWords
        ..clear()
        ..addAll(words);
      _history.clear();
      _newWordProgress.clear();
      _wordStats.clear();
      _sessionDifficultWordIds.clear();
      _current = 0;
      _completed = 0;
      _targetTotal = words.length;
      _newWordStep = 0;
      _revealed = false;
      _isSaving = false;
      _locked = true;
      _feedbackText = '';
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

  Map<ShortcutActivator, VoidCallback> _shortcutBindings(WordEntry word) {
    return {
      const SingleActivator(LogicalKeyboardKey.space): () {
        if (!_revealed) {
          setState(() => _revealed = true);
        }
      },
      const SingleActivator(LogicalKeyboardKey.digit1): () {
        if (_revealed && !_isSaving) {
          _saveReview(word, ReviewRating.forgot);
        }
      },
      const SingleActivator(LogicalKeyboardKey.semicolon): () {
        if (_revealed && !_isSaving) {
          _saveReview(word, ReviewRating.forgot);
        }
      },
      const SingleActivator(LogicalKeyboardKey.digit2): () {
        if (_revealed && !_isSaving) {
          _saveReview(word, ReviewRating.shaky);
        }
      },
      const SingleActivator(LogicalKeyboardKey.quote): () {
        if (_revealed && !_isSaving) {
          _saveReview(word, ReviewRating.shaky);
        }
      },
      const SingleActivator(LogicalKeyboardKey.digit3): () {
        if (_revealed && !_isSaving) {
          _saveReview(word, ReviewRating.known);
        }
      },
      const SingleActivator(LogicalKeyboardKey.enter): () {
        if (_revealed && !_isSaving) {
          _saveReview(word, ReviewRating.known);
        }
      },
      const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
        if (_revealed && !_isSaving) {
          _saveReview(word, ReviewRating.known);
        }
      },
      const SingleActivator(LogicalKeyboardKey.keyS): () {
        speakWord(word.word);
      },
      const SingleActivator(LogicalKeyboardKey.backspace): () {
        _goBack();
      },
      const SingleActivator(LogicalKeyboardKey.delete): () {
        _goBack();
      },
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
        _goBack();
      },
    };
  }

  Future<void> _saveReview(WordEntry word, ReviewRating rating) async {
    _recordAttempt(word, rating);
    _showFeedback(rating);
    if (widget.isNewStudy) {
      _saveNewWordReview(word, rating);
      return;
    }
    final store = AppScope.of(context);
    _advanceReviewCard();
    store.recordReview(word, rating).catchError((Object error) {
      debugPrint('Failed to save review for ${word.word}: $error');
    });
  }

  void _advanceReviewCard() {
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

  void _saveNewWordReview(WordEntry word, ReviewRating rating) {
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

    final store = AppScope.of(context);
    if (mastered) {
      store.completeNewWord(word, firstSightKnown: firstSightKnown).catchError((
        Object error,
      ) {
        debugPrint('Failed to save new word ${word.word}: $error');
      });
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

  void _recordAttempt(WordEntry word, ReviewRating rating) {
    final stat = _wordStats.putIfAbsent(
      word.id,
      () => _StudyWordStat(word: word),
    );
    stat.attempts += 1;
    switch (rating) {
      case ReviewRating.forgot:
        stat.forgot += 1;
        _sessionDifficultWordIds.add(word.id);
      case ReviewRating.shaky:
        stat.shaky += 1;
        _sessionDifficultWordIds.add(word.id);
      case ReviewRating.known:
        stat.known += 1;
    }
  }

  void _showFeedback(ReviewRating rating) {
    final (text, color) = switch (rating) {
      ReviewRating.forgot => ('已记录：不认识，会尽快再出现', ReciteColors.red),
      ReviewRating.shaky => ('已记录：模糊，会加强巩固', ReciteColors.orange),
      ReviewRating.known => ('已记录：认识', ReciteColors.teal),
    };
    setState(() {
      _feedbackText = text;
      _feedbackColor = color;
    });
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _feedbackText != text) {
        return;
      }
      setState(() => _feedbackText = '');
    });
  }

  _StudySummary _buildSummary() {
    final stats = _wordStats.values.toList()
      ..sort((a, b) => b.attempts.compareTo(a.attempts));
    final repeated = stats.where((item) => item.attempts > 1).toList();
    final difficult = stats
        .where(
          (item) =>
              _sessionDifficultWordIds.contains(item.word.id) ||
              item.attempts >= 3,
        )
        .toList();
    return _StudySummary(
      mastered: _completed,
      repeated: repeated,
      difficult: difficult,
      forgotCount: stats.fold(0, (total, item) => total + item.forgot),
      shakyCount: stats.fold(0, (total, item) => total + item.shaky),
      knownCount: stats.fold(0, (total, item) => total + item.known),
    );
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

class _StudyModeSelector extends StatelessWidget {
  const _StudyModeSelector({required this.value, required this.onChanged});

  final StudyMode value;
  final ValueChanged<StudyMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        if (compact) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StudyModeChip(
                value: StudyMode.review,
                selected: value == StudyMode.review,
                icon: Icons.repeat_rounded,
                label: '复习',
                onSelected: onChanged,
              ),
              _StudyModeChip(
                value: StudyMode.newWords,
                selected: value == StudyMode.newWords,
                icon: Icons.auto_stories_rounded,
                label: '学新词',
                onSelected: onChanged,
              ),
              _StudyModeChip(
                value: StudyMode.difficult,
                selected: value == StudyMode.difficult,
                icon: Icons.local_fire_department_rounded,
                label: '困难词',
                onSelected: onChanged,
              ),
            ],
          );
        }
        return SegmentedButton<StudyMode>(
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
            ButtonSegment(
              value: StudyMode.difficult,
              icon: Icon(Icons.local_fire_department_rounded),
              label: Text('困难词'),
            ),
          ],
          selected: {value},
          onSelectionChanged: (next) => onChanged(next.first),
        );
      },
    );
  }
}

class _StudyModeChip extends StatelessWidget {
  const _StudyModeChip({
    required this.value,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final StudyMode value;
  final bool selected;
  final IconData icon;
  final String label;
  final ValueChanged<StudyMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _StudyActionRail extends StatelessWidget {
  const _StudyActionRail({
    required this.revealed,
    required this.isSaving,
    required this.onReveal,
    required this.onForgot,
    required this.onShaky,
    required this.onKnown,
  });

  final bool revealed;
  final bool isSaving;
  final VoidCallback onReveal;
  final VoidCallback onForgot;
  final VoidCallback onShaky;
  final VoidCallback onKnown;

  @override
  Widget build(BuildContext context) {
    if (!revealed) {
      return _RailButton(
        label: '答案',
        shortcut: 'Space',
        icon: Icons.visibility_rounded,
        onPressed: onReveal,
        filled: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _RailButton(
            label: '认识',
            shortcut: 'Enter',
            icon: Icons.check_rounded,
            onPressed: isSaving ? null : onKnown,
            filled: true,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _RailButton(
            label: '模糊',
            shortcut: "'",
            icon: Icons.remove_rounded,
            onPressed: isSaving ? null : onShaky,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _RailButton(
            label: '不认识',
            shortcut: ';',
            icon: Icons.close_rounded,
            onPressed: isSaving ? null : onForgot,
          ),
        ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.label,
    required this.shortcut,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final String shortcut;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            shortcut,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
    final style = ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    return filled
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

class _NewWordProgress {
  int attempts = 0;
  int spacedKnownHits = 0;
  int? lastKnownStep;
}

class _StudyWordStat {
  _StudyWordStat({required this.word});

  final WordEntry word;
  int attempts = 0;
  int forgot = 0;
  int shaky = 0;
  int known = 0;
}

class _StudySummary {
  const _StudySummary({
    required this.mastered,
    required this.repeated,
    required this.difficult,
    required this.forgotCount,
    required this.shakyCount,
    required this.knownCount,
  });

  final int mastered;
  final List<_StudyWordStat> repeated;
  final List<_StudyWordStat> difficult;
  final int forgotCount;
  final int shakyCount;
  final int knownCount;
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: text.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey(text),
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.24)),
                ),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
    );
  }
}

class _FlipTransition extends StatelessWidget {
  const _FlipTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final value = curved.value;
        final angle = (1 - value) * math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.label,
    required this.completed,
    required this.total,
    required this.progress,
    required this.onBack,
  });

  final String label;
  final int completed;
  final int total;
  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
    required this.isNewStudy,
    required this.summary,
    required this.onRefresh,
  });

  final String modeLabel;
  final int completed;
  final int total;
  final bool isNewStudy;
  final _StudySummary summary;
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                isNewStudy
                    ? '本轮掌握 $completed 个新词，反复出现 ${summary.repeated.length} 个，困难词 ${summary.difficult.length} 个。'
                    : '本轮完成 $completed 张复习卡，困难词 ${summary.difficult.length} 个。',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SummaryChip(
                    label: isNewStudy ? '掌握' : '完成',
                    value: completed.toString(),
                    color: ReciteColors.teal,
                  ),
                  _SummaryChip(
                    label: '不认识',
                    value: summary.forgotCount.toString(),
                    color: ReciteColors.red,
                  ),
                  _SummaryChip(
                    label: '模糊',
                    value: summary.shakyCount.toString(),
                    color: ReciteColors.orange,
                  ),
                  _SummaryChip(
                    label: '认识',
                    value: summary.knownCount.toString(),
                    color: ReciteColors.blue,
                  ),
                ],
              ),
              if (!isNewStudy) ...[
                const SizedBox(height: 14),
                FutureBuilder<int>(
                  future: AppScope.of(context).countTomorrowDueWords(),
                  builder: (context, snapshot) {
                    final count = snapshot.data;
                    return Text(
                      count == null ? '正在估算明日复习量...' : '明日预计复习量：$count 个到期词。',
                      style: const TextStyle(color: ReciteColors.muted),
                    );
                  },
                ),
              ],
              if (summary.repeated.isNotEmpty) ...[
                const SizedBox(height: 14),
                _WordStatPreview(title: '本轮反复出现', stats: summary.repeated),
              ],
              if (summary.difficult.isNotEmpty) ...[
                const SizedBox(height: 14),
                _WordStatPreview(title: '困难词', stats: summary.difficult),
              ],
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      side: BorderSide.none,
      backgroundColor: color.withValues(alpha: 0.1),
      label: Text(
        '$label $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _WordStatPreview extends StatelessWidget {
  const _WordStatPreview({required this.title, required this.stats});

  final String title;
  final List<_StudyWordStat> stats;

  @override
  Widget build(BuildContext context) {
    final visible = stats.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final stat in visible)
              Chip(
                label: Text('${stat.word.word} x${stat.attempts}'),
                side: BorderSide.none,
                backgroundColor: ReciteColors.orange.withValues(alpha: 0.12),
              ),
          ],
        ),
      ],
    );
  }
}

class _QuestionContent extends StatelessWidget {
  const _QuestionContent({
    super.key,
    required this.word,
    required this.compact,
  });

  final WordEntry word;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.92,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            word.word,
            maxLines: 1,
            style:
                (compact
                        ? Theme.of(context).textTheme.displaySmall
                        : Theme.of(context).textTheme.displayMedium)
                    ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _AnswerContent extends StatelessWidget {
  const _AnswerContent({required this.word, required this.compact});

  final WordEntry word;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(fontSize: compact ? 14 : null, height: 1.32),
      child: Column(
        key: ValueKey(word.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word.word,
                  maxLines: 1,
                  style:
                      (compact
                              ? Theme.of(context).textTheme.headlineSmall
                              : Theme.of(context).textTheme.headlineMedium)
                          ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
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
          SizedBox(height: compact ? 10 : 18),
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
                      backgroundColor: ReciteColors.blue.withValues(
                        alpha: 0.08,
                      ),
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
      ),
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
