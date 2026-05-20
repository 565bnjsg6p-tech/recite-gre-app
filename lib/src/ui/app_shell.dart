import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_scope.dart';
import '../data/auth_repository.dart';
import '../theme/app_theme.dart';
import 'pages/library_page.dart';
import 'pages/plan_page.dart';
import 'pages/review_page.dart';
import 'pages/settings_page.dart';
import 'pages/today_page.dart';
import 'pages/word_input_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.onChangeLanguage,
  });

  final AppUser user;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onChangeLanguage;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  StudyMode _studyMode = StudyMode.review;
  String? _studyBookKey;
  String? _studyBookLabel;
  bool _legacyPromptScheduled = false;
  bool _legacyPromptShown = false;

  static const _destinations = <_Destination>[
    _Destination('今日', Icons.home_rounded),
    _Destination('学习', Icons.style_rounded),
    _Destination('录入', Icons.add_box_rounded),
    _Destination('词库', Icons.library_books_rounded),
    _Destination('计划', Icons.event_note_rounded),
    _Destination('设置', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_legacyPromptScheduled) {
      _legacyPromptScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _maybeShowLegacyDataPrompt();
        }
      });
    }

    final isWide = MediaQuery.sizeOf(context).width >= 860;
    final pages = <Widget>[
      TodayPage(
        onStartReview: () => _openStudy(StudyMode.review),
        onStartNewWords: () => _openStudy(StudyMode.newWords),
        onStartDifficult: () => _openStudy(StudyMode.difficult),
        onOpenInput: () => _selectPage(2),
      ),
      ReviewPage(
        initialMode: _studyMode,
        initialBookKey: _studyBookKey,
        initialBookLabel: _studyBookLabel,
      ),
      WordInputPage(
        activeStudyBookKey: _studyBookKey,
        onStartBook: (bookKey, bookLabel) => _openStudy(
          StudyMode.newWords,
          bookKey: bookKey,
          bookLabel: bookLabel,
        ),
        onCancelBook: () => _clearStudyBook(),
      ),
      const LibraryPage(),
      const PlanPage(),
      SettingsPage(
        user: widget.user,
        onSignOut: widget.onSignOut,
        onChangeLanguage: widget.onChangeLanguage,
      ),
    ];
    final content = isWide
        ? Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: _BrandMark(),
                  ),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(
                          destination.icon,
                          color: ReciteColors.blue,
                        ),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, color: ReciteColors.line),
                Expanded(child: pages[_index]),
              ],
            ),
          )
        : Scaffold(
            body: pages[_index],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
          );

    return CallbackShortcuts(
      bindings: {
        for (var i = 0; i < _destinations.length; i++)
          SingleActivator(
            LogicalKeyboardKey.digit1.keyId == 0
                ? LogicalKeyboardKey.digit1
                : _numberKey(i + 1),
            control: true,
          ): () =>
              _selectPage(i),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            _selectPage(2),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _selectPage(3),
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): () =>
            _selectPage(1),
      },
      child: Focus(autofocus: true, child: content),
    );
  }

  void _selectPage(int value) {
    setState(() => _index = value);
  }

  void _openStudy(StudyMode mode, {String? bookKey, String? bookLabel}) {
    setState(() {
      _studyMode = mode;
      if (mode == StudyMode.newWords && bookKey != null) {
        _studyBookKey = bookKey;
        _studyBookLabel = bookLabel;
      } else if (mode != StudyMode.newWords) {
        _studyBookKey = null;
        _studyBookLabel = null;
      }
      _index = 1;
    });
  }

  void _clearStudyBook() {
    setState(() {
      _studyBookKey = null;
      _studyBookLabel = null;
    });
  }

  Future<void> _maybeShowLegacyDataPrompt() async {
    if (_legacyPromptShown) {
      return;
    }
    _legacyPromptShown = true;
    final store = AppScope.of(context);
    final legacyCount = await store.countLegacyWords();
    if (!mounted || legacyCount == 0) {
      return;
    }

    final shouldClaim = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现未绑定的本地词库'),
        content: Text(
          '当前浏览器里有 $legacyCount 个还没有绑定账号的单词。要把它们绑定到 ${widget.user.email} 并同步到云端吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('暂不处理'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('绑定并同步'),
          ),
        ],
      ),
    );

    if (!mounted || shouldClaim != true) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    await store.claimLegacyDataForActiveUser();
    messenger.showSnackBar(const SnackBar(content: Text('本地词库已绑定，正在同步到云端。')));
    final result = await store.syncNow();
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '同步完成：上传 ${result.pushed} 条，拉取 ${result.pulled} 条。'
              : result.message,
        ),
      ),
    );
  }

  LogicalKeyboardKey _numberKey(int value) {
    switch (value) {
      case 1:
        return LogicalKeyboardKey.digit1;
      case 2:
        return LogicalKeyboardKey.digit2;
      case 3:
        return LogicalKeyboardKey.digit3;
      case 4:
        return LogicalKeyboardKey.digit4;
      case 5:
        return LogicalKeyboardKey.digit5;
      case 6:
        return LogicalKeyboardKey.digit6;
      default:
        return LogicalKeyboardKey.digit1;
    }
  }
}

class _Destination {
  const _Destination(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ReciteColors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.psychology_alt_rounded, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text('GRE', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
