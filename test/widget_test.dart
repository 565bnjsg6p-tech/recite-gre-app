import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recite_gre_app/recite_app.dart';
import 'package:recite_gre_app/src/data/app_database.dart';
import 'package:recite_gre_app/src/data/app_preferences.dart';
import 'package:recite_gre_app/src/data/app_store.dart';
import 'package:recite_gre_app/src/data/auth_repository.dart';
import 'package:recite_gre_app/src/data/sync_service.dart';
import 'package:recite_gre_app/src/data/word_entry.dart';
import 'package:recite_gre_app/src/data/word_quality.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  testWidgets('Recite app starts on language selection page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(AppDatabase(NativeDatabase.memory()));
    await tester.pumpWidget(
      ReciteApp(store: store, authRepository: LocalAuthRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('选择学习语言'), findsOneWidget);
    expect(find.text('英语'), findsOneWidget);
    expect(find.text('德语'), findsOneWidget);

    await store.disposeStore();
  });

  test('word data is isolated by active user', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final store = AppStore(database);

    await store.activateUser('user_a');
    expect((await store.watchWords().first).length, 3);
    await store.importWords('abate', ImportMode.queueOnly);
    expect(
      (await store.watchWords().first).any((word) => word.word == 'abate'),
      isTrue,
    );

    await store.activateUser('user_b');
    final userBWords = await store.watchWords().first;
    expect(userBWords.length, 3);
    expect(userBWords.any((word) => word.word == 'abate'), isFalse);

    await store.activateUser('user_a');
    final userAWords = await store.watchWords().first;
    expect(userAWords.any((word) => word.word == 'abate'), isTrue);

    await store.disposeStore();
  });

  test('review logs can be marked as synced', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final store = AppStore(database);

    await store.activateUser('user_a');
    final word = (await store.watchWords().first).first;
    await database.addReviewLog(
      userId: 'user_a',
      wordId: word.id,
      rating: 'good',
      reviewedAt: DateTime(2026, 5, 18, 9),
    );

    final pendingLogs = await database.getPendingReviewLogChanges('user_a');
    expect(pendingLogs, hasLength(1));
    expect(await database.countPendingSync('user_a'), greaterThan(0));

    await database.markReviewLogSynced(
      userId: 'user_a',
      logId: pendingLogs.single.id,
      remoteId: 'remote-review-1',
      updatedAt: pendingLogs.single.updatedAt!,
    );

    expect(await database.getPendingReviewLogChanges('user_a'), isEmpty);

    await store.disposeStore();
  });

  test('known review uses simplified sm2 scheduling', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final store = AppStore(database);

    await store.activateUser('user_a');
    final word = (await store.watchWords().first).firstWhere(
      (item) => item.reviewCount == 0,
    );
    await store.recordReview(word, ReviewRating.known);

    final row = await database.getWordById('user_a', word.id);
    expect(row, isNotNull);
    expect(row!.reviewCount, 1);
    expect(row.intervalDays, 1);
    expect(row.easeFactor, 260);
    expect(row.dueAt.isAfter(DateTime.now()), isTrue);

    await store.disposeStore();
  });

  test('study plan saves new word target and computes review count', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    final store = AppStore(database);

    await store.activateUser('user_a');
    await store.saveStudyPlan(
      dailyNewWords: 42,
      examDate: DateTime(2026, 8, 1),
    );

    final plan = await store.getStudyPlan();
    expect(plan.dailyNewWords, 42);
    expect(plan.dailyReviewLimit, 1);
    expect(plan.examDateLabel, '2026.08.01');
    expect(await store.preferences.hasPendingStudySettings(), isTrue);

    await store.disposeStore();
  });

  test('backup export can be previewed and imported', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final store = AppStore(database);

    await store.activateUser('user_a');
    await store.importWords('abate', ImportMode.dictionary);
    final word = (await store.watchWords().first).firstWhere(
      (item) => item.word == 'abate',
    );
    await store.recordReview(word, ReviewRating.known);

    final backup = await store.exportBackupJson();
    final preview = store.previewBackupJson(backup);
    expect(preview.wordCount, greaterThanOrEqualTo(4));
    expect(preview.reviewLogCount, 1);
    expect(preview.dictionaryWordCount, greaterThanOrEqualTo(1));

    await store.activateUser('user_b');
    final result = await store.importBackupJson(backup, replace: true);
    expect(result.replaced, isTrue);
    expect(result.importedWords, preview.wordCount);
    expect(result.importedReviewLogs, preview.reviewLogCount);

    await store.disposeStore();
  });

  test('ai content quality flags incomplete study cards', () {
    final incomplete = evaluateAiContent(
      chineseMeaning: 'n. 浪费者',
      englishMeaning: 'a spender',
      greFocus: '',
      roots: const [],
      synonyms: const ['wasteful'],
      antonyms: const [],
      example: '',
      memoryTip: '暂无',
      tags: const ['GRE'],
    );
    expect(incomplete.isAcceptable, isFalse);
    expect(incomplete.missingRequired, contains('GRE 考点'));
    expect(incomplete.missingRequired, contains('词根词缀'));

    final complete = evaluateAiContent(
      chineseMeaning: 'adj. 偏离常规的；异常的；常作贬义。',
      englishMeaning:
          'Deviating from what is normal, expected, or morally acceptable.',
      greFocus: 'GRE 中常和 normal、typical 构成反义替换，也用于描述异常行为。',
      roots: const [RootPart(part: 'ab-', meaning: 'away from')],
      synonyms: const ['anomalous', 'deviant'],
      antonyms: const ['normal'],
      example:
          'The scientist noticed an aberrant reading that forced the team to repeat the experiment.',
      memoryTip: 'ab 表示偏离，err 像 error，偏离正常轨道就是异常。',
      tags: const ['高频', '反义'],
    );
    expect(complete.isAcceptable, isTrue);
    expect(complete.score, greaterThanOrEqualTo(80));
  });

  test('sync attempts are recorded in local sync log', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    final preferences = AppPreferences();
    final store = AppStore(
      database,
      preferences: preferences,
      syncService: PlaceholderSyncService(
        database: database,
        preferences: preferences,
      ),
    );

    await store.activateUser('user_a');
    final result = await store.syncNow();
    final logs = await store.getSyncLogs();

    expect(result.success, isFalse);
    expect(logs, hasLength(1));
    expect(logs.single.success, isFalse);
    expect(logs.single.message, contains('Supabase'));

    await store.disposeStore();
  });

  test('batch edits can tag, mark difficult, and queue words', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final store = AppStore(database);

    await store.activateUser('user_a');
    final words = await store.watchWords().first;
    final ids = words.take(2).map((word) => word.id).toList();

    final tagResult = await store.addTagsToWords(ids, '易混, 高频');
    expect(tagResult.changed, 2);
    final tagged = await store.watchWords().first;
    expect(
      tagged
          .where((word) => ids.contains(word.id))
          .every(
            (word) => word.tags.contains('易混') && word.tags.contains('高频'),
          ),
      isTrue,
    );

    final difficultResult = await store.markWordsDifficult(ids);
    expect(difficultResult.changed, 2);
    final difficultRows = await database.getWordsByIds('user_a', ids);
    expect(difficultRows.every((row) => row.lapseCount >= 1), isTrue);
    expect(difficultRows.every((row) => row.easeFactor <= 210), isTrue);

    final queueResult = await store.queueManyForAi(ids);
    expect(queueResult.changed, 2);
    final queuedRows = await database.getWordsByIds('user_a', ids);
    expect(
      queuedRows.every((row) => row.enrichmentStatus == 'queued_ai'),
      isTrue,
    );

    await store.disposeStore();
  });

  test(
    'study dashboard summarizes activity and tomorrow review load',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final store = AppStore(database);

      await store.activateUser('user_a');
      final word = (await store.watchWords().first).first;
      await database.addReviewLog(
        userId: 'user_a',
        wordId: word.id,
        rating: 'known',
        reviewedAt: DateTime.now(),
      );

      final dashboard = await store.watchStudyDashboard().first;
      expect(dashboard.streakDays, greaterThanOrEqualTo(1));
      expect(dashboard.activeRate7, greaterThan(0));
      expect(dashboard.reviewableWords, greaterThan(0));
      expect(dashboard.tomorrowReviewWords, greaterThanOrEqualTo(0));

      await store.disposeStore();
    },
  );

  test('diagnostic report omits secret values', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    final store = AppStore(database);

    await store.activateUser('user_a');
    await store.saveApiKey('sk-test-secret');
    await store.saveApiBaseUrl('https://api.example.com');
    final report = await store.buildDiagnosticReport();

    expect(report, contains('hasApiKey'));
    expect(report, contains('hasApiBaseUrl'));
    expect(report, isNot(contains('sk-test-secret')));
    expect(report, isNot(contains('https://api.example.com')));

    await store.disposeStore();
  });

  test('legacy local database schema is repaired on startup', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE word_cards (
        id TEXT NOT NULL PRIMARY KEY,
        word TEXT NOT NULL UNIQUE,
        chinese_meaning TEXT NOT NULL,
        english_meaning TEXT NOT NULL,
        gre_focus TEXT NOT NULL,
        roots_json TEXT NOT NULL DEFAULT '[]',
        synonyms_json TEXT NOT NULL DEFAULT '[]',
        antonyms_json TEXT NOT NULL DEFAULT '[]',
        example TEXT NOT NULL DEFAULT '',
        memory_tip TEXT NOT NULL DEFAULT '',
        note TEXT NOT NULL DEFAULT '',
        tags_json TEXT NOT NULL DEFAULT '[]',
        mastery INTEGER NOT NULL DEFAULT 0,
        due_at INTEGER NOT NULL,
        review_count INTEGER NOT NULL DEFAULT 0,
        lapse_count INTEGER NOT NULL DEFAULT 0,
        enrichment_status TEXT NOT NULL DEFAULT 'queued',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE review_logs (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        word_id TEXT NOT NULL REFERENCES word_cards(id),
        rating TEXT NOT NULL,
        reviewed_at INTEGER NOT NULL
      );
    ''');
    raw.execute(
      '''
      INSERT INTO word_cards (
        id, word, chinese_meaning, english_meaning, gre_focus,
        roots_json, synonyms_json, antonyms_json, mastery, due_at,
        review_count, lapse_count, enrichment_status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, '[]', '[]', '[]', 0, ?, 0, 0, 'queued', ?, ?)
      ''',
      ['legacy:abate', 'abate', '减少', 'to lessen', 'legacy', 1, 1, 1],
    );
    raw.execute('PRAGMA user_version = 3');

    final database = AppDatabase(
      NativeDatabase.opened(raw, closeUnderlyingOnClose: true),
    );
    expect(await database.countLegacyWords(), 1);
    final row = await database.getWordById('local_legacy', 'legacy:abate');
    expect(row, isNotNull);
    expect(row!.remoteId, isNull);
    expect(row.easeFactor, 250);
    expect(row.intervalDays, 0);

    await database.close();
  });

  test('legacy words require explicit claim before account binding', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final store = AppStore(database);
    final now = DateTime(2026, 5, 19, 9);

    await database.upsertWord(
      WordCardsCompanion.insert(
        id: 'local_legacy:umbragex',
        userId: const Value('local_legacy'),
        word: 'umbragex',
        chineseMeaning: '旧本地测试词',
        englishMeaning: 'legacy local test word',
        greFocus: 'legacy migration test',
        dueAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await store.activateUser('user_a');
    expect(await store.countLegacyWords(), 1);
    expect(await database.getWordByText('user_a', 'umbragex'), isNull);

    await store.claimLegacyDataForActiveUser();
    expect(await store.countLegacyWords(), 0);
    expect(await database.getWordByText('user_a', 'umbragex'), isNotNull);

    await store.disposeStore();
  });
}
