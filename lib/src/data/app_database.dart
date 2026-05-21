import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

const _wordColumnNames = [
  'id',
  'user_id',
  'remote_id',
  'sync_status',
  'deleted_at',
  'word',
  'source_type',
  'book_key',
  'chinese_meaning',
  'english_meaning',
  'gre_focus',
  'roots_json',
  'synonyms_json',
  'antonyms_json',
  'example',
  'memory_tip',
  'note',
  'tags_json',
  'mastery',
  'due_at',
  'review_count',
  'lapse_count',
  'ease_factor',
  'interval_days',
  'enrichment_status',
  'created_at',
  'updated_at',
];

const _reviewLogColumnNames = [
  'id',
  'user_id',
  'remote_id',
  'sync_status',
  'deleted_at',
  'word_id',
  'rating',
  'reviewed_at',
  'updated_at',
];

String _createWordCardsTableSql(String tableName) {
  return '''
    CREATE TABLE $tableName (
      id TEXT NOT NULL PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT 'local_legacy',
      remote_id TEXT NULL,
      sync_status TEXT NOT NULL DEFAULT 'dirty',
      deleted_at INTEGER NULL,
      word TEXT NOT NULL,
      source_type TEXT NOT NULL DEFAULT 'personal',
      book_key TEXT NOT NULL DEFAULT '',
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
      ease_factor INTEGER NOT NULL DEFAULT 250,
      interval_days INTEGER NOT NULL DEFAULT 0,
      enrichment_status TEXT NOT NULL DEFAULT 'queued',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';
}

String _createReviewLogsTableSql(String tableName, String wordTableName) {
  return '''
    CREATE TABLE $tableName (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL DEFAULT 'local_legacy',
      remote_id TEXT NULL,
      sync_status TEXT NOT NULL DEFAULT 'dirty',
      deleted_at INTEGER NULL,
      word_id TEXT NOT NULL REFERENCES $wordTableName(id),
      rating TEXT NOT NULL,
      reviewed_at INTEGER NOT NULL,
      updated_at INTEGER NULL
    )
  ''';
}

class WordCards extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('local_legacy'))();
  TextColumn get remoteId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('dirty'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get word => text()();
  TextColumn get sourceType => text().withDefault(const Constant('personal'))();
  TextColumn get bookKey => text().withDefault(const Constant(''))();
  TextColumn get chineseMeaning => text()();
  TextColumn get englishMeaning => text()();
  TextColumn get greFocus => text()();
  TextColumn get rootsJson => text().withDefault(const Constant('[]'))();
  TextColumn get synonymsJson => text().withDefault(const Constant('[]'))();
  TextColumn get antonymsJson => text().withDefault(const Constant('[]'))();
  TextColumn get example => text().withDefault(const Constant(''))();
  TextColumn get memoryTip => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  IntColumn get mastery => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  IntColumn get lapseCount => integer().withDefault(const Constant(0))();
  IntColumn get easeFactor => integer().withDefault(const Constant(250))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  TextColumn get enrichmentStatus =>
      text().withDefault(const Constant('queued'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().withDefault(const Constant('local_legacy'))();
  TextColumn get remoteId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('dirty'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get wordId => text().references(WordCards, #id)();
  TextColumn get rating => text()();
  DateTimeColumn get reviewedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [WordCards, ReviewLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults()
    : super(
        driftDatabase(
          name: 'recite_gre',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      await ensureCompatibleSchema();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement('PRAGMA foreign_keys = OFF');
        await customStatement(_createWordCardsTableSql('word_cards_new'));
        await customStatement('''
          INSERT INTO word_cards_new (
            id, user_id, remote_id, sync_status, deleted_at, word,
            source_type, book_key,
            chinese_meaning, english_meaning, gre_focus, roots_json,
            synonyms_json, antonyms_json, example, memory_tip, note, tags_json,
            mastery, due_at, review_count, lapse_count, enrichment_status,
            created_at, updated_at
          )
          SELECT
            id, 'local_legacy', NULL, 'dirty', NULL, word,
            'personal', '',
            chinese_meaning, english_meaning, gre_focus, roots_json,
            synonyms_json, antonyms_json, example, memory_tip, note, tags_json,
            mastery, due_at, review_count, lapse_count, enrichment_status,
            created_at, updated_at
          FROM word_cards
        ''');
        await customStatement(
          _createReviewLogsTableSql('review_logs_new', 'word_cards_new'),
        );
        await customStatement('''
          INSERT INTO review_logs_new (
            id, user_id, remote_id, sync_status, deleted_at,
            word_id, rating, reviewed_at, updated_at
          )
          SELECT
            id, 'local_legacy', NULL, 'dirty', NULL,
            word_id, rating, reviewed_at, reviewed_at
          FROM review_logs
        ''');
        await customStatement('DROP TABLE review_logs');
        await customStatement('DROP TABLE word_cards');
        await customStatement(
          'ALTER TABLE word_cards_new RENAME TO word_cards',
        );
        await customStatement(
          'ALTER TABLE review_logs_new RENAME TO review_logs',
        );
        await customStatement('PRAGMA foreign_keys = ON');
      }
      if (from < 3) {
        await m.addColumn(wordCards, wordCards.easeFactor);
        await m.addColumn(wordCards, wordCards.intervalDays);
      }
      if (from < 4) {
        await m.addColumn(wordCards, wordCards.sourceType);
        await m.addColumn(wordCards, wordCards.bookKey);
      }
    },
  );

  Future<void> ensureCompatibleSchema() async {
    await _repairLegacySchemaIfNeeded();
  }

  Future<void> _repairLegacySchemaIfNeeded() async {
    final wordColumns = await _tableColumns('word_cards');
    if (wordColumns.isEmpty) {
      return;
    }
    final reviewColumns = await _tableColumns('review_logs');
    final needsWordRepair = _wordColumnNames.any(
      (column) => !wordColumns.contains(column),
    );
    final needsReviewRepair =
        reviewColumns.isNotEmpty &&
        _reviewLogColumnNames.any((column) => !reviewColumns.contains(column));
    if (!needsWordRepair && !needsReviewRepair) {
      return;
    }

    await customStatement('PRAGMA foreign_keys = OFF');
    await customStatement('DROP TABLE IF EXISTS review_logs_repaired');
    await customStatement('DROP TABLE IF EXISTS word_cards_repaired');
    await customStatement(_createWordCardsTableSql('word_cards_repaired'));
    await customStatement('''
      INSERT OR REPLACE INTO word_cards_repaired (
        ${_wordColumnNames.join(', ')}
      )
      SELECT
        ${_wordColumnNames.map((column) => _selectLegacyWordColumn(column, wordColumns)).join(',\n        ')}
      FROM word_cards
    ''');

    if (reviewColumns.isNotEmpty) {
      await customStatement(
        _createReviewLogsTableSql(
          'review_logs_repaired',
          'word_cards_repaired',
        ),
      );
      await customStatement('''
        INSERT OR REPLACE INTO review_logs_repaired (
          ${_reviewLogColumnNames.join(', ')}
        )
        SELECT
          ${_reviewLogColumnNames.map((column) => _selectLegacyReviewColumn(column, reviewColumns)).join(',\n          ')}
        FROM review_logs
      ''');
      await customStatement('DROP TABLE review_logs');
    }
    await customStatement('DROP TABLE word_cards');
    await customStatement(
      'ALTER TABLE word_cards_repaired RENAME TO word_cards',
    );
    if (reviewColumns.isNotEmpty) {
      await customStatement(
        'ALTER TABLE review_logs_repaired RENAME TO review_logs',
      );
    }
    await customStatement('PRAGMA foreign_keys = ON');
  }

  Future<Set<String>> _tableColumns(String tableName) async {
    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return {
      for (final row in rows)
        if (row.data['name'] != null) row.data['name'].toString(),
    };
  }

  String _selectLegacyWordColumn(String column, Set<String> existingColumns) {
    if (existingColumns.contains(column)) {
      return column;
    }
    return switch (column) {
      'user_id' => "'local_legacy' AS user_id",
      'remote_id' => 'NULL AS remote_id',
      'sync_status' => "'dirty' AS sync_status",
      'deleted_at' => 'NULL AS deleted_at',
      'source_type' => "'personal' AS source_type",
      'book_key' => "'' AS book_key",
      'roots_json' => "'[]' AS roots_json",
      'synonyms_json' => "'[]' AS synonyms_json",
      'antonyms_json' => "'[]' AS antonyms_json",
      'example' => "'' AS example",
      'memory_tip' => "'' AS memory_tip",
      'note' => "'' AS note",
      'tags_json' => "'[]' AS tags_json",
      'mastery' => '0 AS mastery',
      'review_count' => '0 AS review_count',
      'lapse_count' => '0 AS lapse_count',
      'ease_factor' => '250 AS ease_factor',
      'interval_days' => '0 AS interval_days',
      'enrichment_status' => "'queued' AS enrichment_status",
      'created_at' => 'strftime(\'%s\', \'now\') * 1000 AS created_at',
      'updated_at' => 'strftime(\'%s\', \'now\') * 1000 AS updated_at',
      _ => "'' AS $column",
    };
  }

  String _selectLegacyReviewColumn(String column, Set<String> existingColumns) {
    if (existingColumns.contains(column)) {
      return column;
    }
    return switch (column) {
      'user_id' => "'local_legacy' AS user_id",
      'remote_id' => 'NULL AS remote_id',
      'sync_status' => "'dirty' AS sync_status",
      'deleted_at' => 'NULL AS deleted_at',
      'updated_at' =>
        existingColumns.contains('reviewed_at')
            ? 'reviewed_at AS updated_at'
            : 'strftime(\'%s\', \'now\') * 1000 AS updated_at',
      _ => "'' AS $column",
    };
  }

  Stream<List<WordCard>> watchAllWords(String userId) {
    return (select(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.word)]))
        .watch();
  }

  Stream<List<WordCard>> watchDueWords(String userId, DateTime now) {
    return (select(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.deletedAt.isNull())
          ..where((table) => table.dueAt.isSmallerOrEqualValue(now))
          ..orderBy([
            (table) => OrderingTerm.asc(table.dueAt),
            (table) => OrderingTerm.asc(table.word),
          ]))
        .watch();
  }

  Future<List<WordCard>> getAllWords(String userId) {
    return (select(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.word)]))
        .get();
  }

  Future<List<WordCard>> getPendingWordChanges(String userId) {
    return (select(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where(
            (table) =>
                table.syncStatus.equals('dirty') |
                table.syncStatus.equals('deleted'),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.updatedAt)]))
        .get();
  }

  Future<WordCard?> getWordByRemoteId(String userId, String remoteId) {
    return (select(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.remoteId.equals(remoteId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<WordCard?> getWordById(String userId, String wordId) {
    return (select(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.id.equals(wordId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<WordCard>> getWordsByIds(String userId, List<String> ids) {
    if (ids.isEmpty) {
      return Future.value(const <WordCard>[]);
    }
    return (select(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.deletedAt.isNull())
          ..where((table) => table.id.isIn(ids)))
        .get();
  }

  Future<WordCard?> getWordByText(String userId, String word) {
    return (select(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.word.equals(word))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<WordCard?> getWordByIdentity({
    required String userId,
    required String sourceType,
    required String bookKey,
    required String word,
  }) {
    return (select(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.sourceType.equals(sourceType))
          ..where((table) => table.bookKey.equals(bookKey))
          ..where((table) => table.word.equals(word))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<ReviewLog>> getAllReviewLogs(String userId) {
    return (select(reviewLogs)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.reviewedAt)]))
        .get();
  }

  Future<List<ReviewLog>> getReviewLogsSince(String userId, DateTime since) {
    return (select(reviewLogs)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.deletedAt.isNull())
          ..where((table) => table.reviewedAt.isBiggerOrEqualValue(since))
          ..orderBy([(table) => OrderingTerm.asc(table.reviewedAt)]))
        .get();
  }

  Future<List<ReviewLog>> getPendingReviewLogChanges(String userId) {
    return (select(reviewLogs)
          ..where((table) => table.userId.equals(userId))
          ..where(
            (table) =>
                table.syncStatus.equals('dirty') |
                table.syncStatus.equals('deleted'),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.updatedAt)]))
        .get();
  }

  Future<ReviewLog?> getReviewLogByRemoteId(String userId, String remoteId) {
    return (select(reviewLogs)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.remoteId.equals(remoteId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> countReviewLogsSince(String userId, DateTime since) async {
    final countExpression = reviewLogs.id.count();
    final query = selectOnly(reviewLogs)
      ..addColumns([countExpression])
      ..where(reviewLogs.userId.equals(userId))
      ..where(reviewLogs.deletedAt.isNull())
      ..where(reviewLogs.reviewedAt.isBiggerOrEqualValue(since));
    return await query.map((row) => row.read(countExpression) ?? 0).getSingle();
  }

  Future<int> countWords(String userId) async {
    final countExpression = wordCards.id.count();
    final query = selectOnly(wordCards)
      ..addColumns([countExpression])
      ..where(wordCards.userId.equals(userId))
      ..where(wordCards.deletedAt.isNull());
    return await query.map((row) => row.read(countExpression) ?? 0).getSingle();
  }

  Future<int> countLegacyWords() async {
    final countExpression = wordCards.id.count();
    final query = selectOnly(wordCards)
      ..addColumns([countExpression])
      ..where(wordCards.userId.equals('local_legacy'))
      ..where(wordCards.deletedAt.isNull());
    return await query.map((row) => row.read(countExpression) ?? 0).getSingle();
  }

  Future<int> countPendingSync(String userId) async {
    final wordCount = wordCards.id.count();
    final wordQuery = selectOnly(wordCards)
      ..addColumns([wordCount])
      ..where(wordCards.userId.equals(userId))
      ..where(
        wordCards.syncStatus.equals('dirty') |
            wordCards.syncStatus.equals('deleted'),
      );
    final words = await wordQuery
        .map((row) => row.read(wordCount) ?? 0)
        .getSingle();

    final logCount = reviewLogs.id.count();
    final logQuery = selectOnly(reviewLogs)
      ..addColumns([logCount])
      ..where(reviewLogs.userId.equals(userId))
      ..where(
        reviewLogs.syncStatus.equals('dirty') |
            reviewLogs.syncStatus.equals('deleted'),
      );
    final logs = await logQuery
        .map((row) => row.read(logCount) ?? 0)
        .getSingle();
    return words + logs;
  }

  Future<void> claimLegacyData(String userId, DateTime updatedAt) async {
    await transaction(() async {
      await (update(
        wordCards,
      )..where((table) => table.userId.equals('local_legacy'))).write(
        WordCardsCompanion(
          userId: Value(userId),
          syncStatus: const Value('dirty'),
          updatedAt: Value(updatedAt),
        ),
      );
      await (update(
        reviewLogs,
      )..where((table) => table.userId.equals('local_legacy'))).write(
        ReviewLogsCompanion(
          userId: Value(userId),
          syncStatus: const Value('dirty'),
          updatedAt: Value(updatedAt),
        ),
      );
    });
  }

  Future<void> upsertWord(WordCardsCompanion word) {
    return into(wordCards).insertOnConflictUpdate(word);
  }

  Future<void> upsertWords(List<WordCardsCompanion> words) {
    if (words.isEmpty) {
      return Future.value();
    }
    return batch((batch) {
      batch.insertAllOnConflictUpdate(wordCards, words);
    });
  }

  Future<int> markWordSynced({
    required String userId,
    required String wordId,
    required String remoteId,
    required DateTime updatedAt,
  }) {
    return (update(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.id.equals(wordId)))
        .write(
          WordCardsCompanion(
            remoteId: Value(remoteId),
            syncStatus: const Value('synced'),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> markLocalOnlyDeletedWordSynced({
    required String userId,
    required String wordId,
  }) {
    return (delete(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.id.equals(wordId)))
        .go();
  }

  Future<int> markReviewLogSynced({
    required String userId,
    required int logId,
    required String remoteId,
    required DateTime updatedAt,
  }) {
    return (update(reviewLogs)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.id.equals(logId)))
        .write(
          ReviewLogsCompanion(
            remoteId: Value(remoteId),
            syncStatus: const Value('synced'),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> markLocalOnlyDeletedReviewLogSynced({
    required String userId,
    required int logId,
  }) {
    return (delete(reviewLogs)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.id.equals(logId)))
        .go();
  }

  Future<int> upsertRemoteReviewLog({
    required String userId,
    required int? localId,
    required String remoteId,
    required String wordId,
    required String rating,
    required DateTime reviewedAt,
    required DateTime updatedAt,
    required DateTime? deletedAt,
  }) {
    if (localId != null) {
      return (update(reviewLogs)
            ..where((table) => table.userId.equals(userId))
            ..where((table) => table.id.equals(localId)))
          .write(
            ReviewLogsCompanion(
              remoteId: Value(remoteId),
              syncStatus: const Value('synced'),
              deletedAt: Value(deletedAt),
              wordId: Value(wordId),
              rating: Value(rating),
              reviewedAt: Value(reviewedAt),
              updatedAt: Value(updatedAt),
            ),
          );
    }
    return into(reviewLogs).insert(
      ReviewLogsCompanion.insert(
        userId: Value(userId),
        remoteId: Value(remoteId),
        syncStatus: const Value('synced'),
        deletedAt: Value(deletedAt),
        wordId: wordId,
        rating: rating,
        reviewedAt: reviewedAt,
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<int> updateEnrichmentStatus({
    required String userId,
    required String wordId,
    required String status,
    required DateTime updatedAt,
  }) {
    return (update(wordCards)
          ..where((table) => table.id.equals(wordId))
          ..where((table) => table.userId.equals(userId)))
        .write(
          WordCardsCompanion(
            enrichmentStatus: Value(status),
            syncStatus: const Value('dirty'),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> updateAiEnrichment({
    required String userId,
    required String wordId,
    required String chineseMeaning,
    required String englishMeaning,
    required String greFocus,
    required String rootsJson,
    required String synonymsJson,
    required String antonymsJson,
    required String example,
    required String memoryTip,
    required String tagsJson,
    String enrichmentStatus = 'ai',
    required DateTime updatedAt,
  }) {
    return (update(wordCards)
          ..where((table) => table.id.equals(wordId))
          ..where((table) => table.userId.equals(userId)))
        .write(
          WordCardsCompanion(
            chineseMeaning: Value(chineseMeaning),
            englishMeaning: Value(englishMeaning),
            greFocus: Value(greFocus),
            rootsJson: Value(rootsJson),
            synonymsJson: Value(synonymsJson),
            antonymsJson: Value(antonymsJson),
            example: Value(example),
            memoryTip: Value(memoryTip),
            tagsJson: Value(tagsJson),
            enrichmentStatus: Value(enrichmentStatus),
            syncStatus: const Value('dirty'),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> updateDictionaryEnrichment({
    required String userId,
    required String wordId,
    required String chineseMeaning,
    required String englishMeaning,
    required String greFocus,
    required String memoryTip,
    required String tagsJson,
    required DateTime updatedAt,
  }) {
    return (update(wordCards)
          ..where((table) => table.id.equals(wordId))
          ..where((table) => table.userId.equals(userId)))
        .write(
          WordCardsCompanion(
            chineseMeaning: Value(chineseMeaning),
            englishMeaning: Value(englishMeaning),
            greFocus: Value(greFocus),
            rootsJson: const Value('[]'),
            synonymsJson: const Value('[]'),
            antonymsJson: const Value('[]'),
            example: const Value(''),
            memoryTip: Value(memoryTip),
            tagsJson: Value(tagsJson),
            enrichmentStatus: const Value('dictionary'),
            syncStatus: const Value('dirty'),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> updateWordContent({
    required String userId,
    required String wordId,
    required String chineseMeaning,
    required String englishMeaning,
    required String greFocus,
    required String rootsJson,
    required String synonymsJson,
    required String antonymsJson,
    required String example,
    required String memoryTip,
    required String note,
    required String tagsJson,
    required DateTime updatedAt,
  }) {
    return (update(wordCards)
          ..where((table) => table.id.equals(wordId))
          ..where((table) => table.userId.equals(userId)))
        .write(
          WordCardsCompanion(
            chineseMeaning: Value(chineseMeaning),
            englishMeaning: Value(englishMeaning),
            greFocus: Value(greFocus),
            rootsJson: Value(rootsJson),
            synonymsJson: Value(synonymsJson),
            antonymsJson: Value(antonymsJson),
            example: Value(example),
            memoryTip: Value(memoryTip),
            note: Value(note),
            tagsJson: Value(tagsJson),
            syncStatus: const Value('dirty'),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> updateNote(
    String userId,
    String wordId,
    String note,
    DateTime updatedAt,
  ) {
    return (update(wordCards)
          ..where((table) => table.id.equals(wordId))
          ..where((table) => table.userId.equals(userId)))
        .write(
          WordCardsCompanion(
            note: Value(note),
            syncStatus: const Value('dirty'),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> updateWordTags({
    required String userId,
    required String wordId,
    required String tagsJson,
    required DateTime updatedAt,
  }) {
    return (update(wordCards)
          ..where((table) => table.id.equals(wordId))
          ..where((table) => table.userId.equals(userId)))
        .write(
          WordCardsCompanion(
            tagsJson: Value(tagsJson),
            syncStatus: const Value('dirty'),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> markWordsDifficultByIds({
    required String userId,
    required List<String> ids,
    required DateTime updatedAt,
  }) {
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.deletedAt.isNull())
          ..where((table) => table.id.isIn(ids)))
        .write(
          WordCardsCompanion(
            mastery: const Value(1),
            lapseCount: const Value(1),
            easeFactor: const Value(210),
            syncStatus: const Value('dirty'),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<void> addReviewLog({
    required String userId,
    required String wordId,
    required String rating,
    required DateTime reviewedAt,
  }) {
    return into(reviewLogs).insert(
      ReviewLogsCompanion.insert(
        userId: Value(userId),
        wordId: wordId,
        rating: rating,
        reviewedAt: reviewedAt,
        updatedAt: Value(reviewedAt),
      ),
    );
  }

  Future<int> updateReviewState({
    required String userId,
    required String wordId,
    required int mastery,
    required DateTime dueAt,
    required int reviewCount,
    required int lapseCount,
    required int easeFactor,
    required int intervalDays,
    required DateTime updatedAt,
  }) {
    return (update(wordCards)
          ..where((table) => table.id.equals(wordId))
          ..where((table) => table.userId.equals(userId)))
        .write(
          WordCardsCompanion(
            mastery: Value(mastery),
            dueAt: Value(dueAt),
            reviewCount: Value(reviewCount),
            lapseCount: Value(lapseCount),
            easeFactor: Value(easeFactor),
            intervalDays: Value(intervalDays),
            syncStatus: const Value('dirty'),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> deleteWordsByIds(String userId, List<String> ids) async {
    if (ids.isEmpty) {
      return 0;
    }
    final now = DateTime.now();
    await (update(reviewLogs)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.wordId.isIn(ids)))
        .write(
          ReviewLogsCompanion(
            deletedAt: Value(now),
            syncStatus: const Value('deleted'),
            updatedAt: Value(now),
          ),
        );
    return (update(wordCards)
          ..where((table) => table.userId.equals(userId))
          ..where((table) => table.id.isIn(ids)))
        .write(
          WordCardsCompanion(
            deletedAt: Value(now),
            syncStatus: const Value('deleted'),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> clearAllData(String userId) {
    return transaction(() async {
      final now = DateTime.now();
      await (update(
        reviewLogs,
      )..where((table) => table.userId.equals(userId))).write(
        ReviewLogsCompanion(
          deletedAt: Value(now),
          syncStatus: const Value('deleted'),
          updatedAt: Value(now),
        ),
      );
      await (update(
        wordCards,
      )..where((table) => table.userId.equals(userId))).write(
        WordCardsCompanion(
          deletedAt: Value(now),
          syncStatus: const Value('deleted'),
          updatedAt: Value(now),
        ),
      );
    });
  }
}
