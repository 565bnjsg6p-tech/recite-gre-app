import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recite_gre_app/recite_app.dart';
import 'package:recite_gre_app/src/data/app_database.dart';
import 'package:recite_gre_app/src/data/app_store.dart';
import 'package:recite_gre_app/src/data/auth_repository.dart';
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

  test('study plan saves as pending sync settings', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    final store = AppStore(database);

    await store.activateUser('user_a');
    await store.saveStudyPlan(
      dailyNewWords: 42,
      dailyReviewLimit: 120,
      examDate: DateTime(2026, 8, 1),
    );

    final plan = await store.getStudyPlan();
    expect(plan.dailyNewWords, 42);
    expect(plan.dailyReviewLimit, 120);
    expect(plan.examDateLabel, '2026.08.01');
    expect(await store.preferences.hasPendingStudySettings(), isTrue);

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
