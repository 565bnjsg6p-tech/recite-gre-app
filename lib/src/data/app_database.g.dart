// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WordCardsTable extends WordCards
    with TableInfo<$WordCardsTable, WordCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_legacy'),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dirty'),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('personal'),
  );
  static const VerificationMeta _bookKeyMeta = const VerificationMeta(
    'bookKey',
  );
  @override
  late final GeneratedColumn<String> bookKey = GeneratedColumn<String>(
    'book_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _chineseMeaningMeta = const VerificationMeta(
    'chineseMeaning',
  );
  @override
  late final GeneratedColumn<String> chineseMeaning = GeneratedColumn<String>(
    'chinese_meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _englishMeaningMeta = const VerificationMeta(
    'englishMeaning',
  );
  @override
  late final GeneratedColumn<String> englishMeaning = GeneratedColumn<String>(
    'english_meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _greFocusMeta = const VerificationMeta(
    'greFocus',
  );
  @override
  late final GeneratedColumn<String> greFocus = GeneratedColumn<String>(
    'gre_focus',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rootsJsonMeta = const VerificationMeta(
    'rootsJson',
  );
  @override
  late final GeneratedColumn<String> rootsJson = GeneratedColumn<String>(
    'roots_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _synonymsJsonMeta = const VerificationMeta(
    'synonymsJson',
  );
  @override
  late final GeneratedColumn<String> synonymsJson = GeneratedColumn<String>(
    'synonyms_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _antonymsJsonMeta = const VerificationMeta(
    'antonymsJson',
  );
  @override
  late final GeneratedColumn<String> antonymsJson = GeneratedColumn<String>(
    'antonyms_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _memoryTipMeta = const VerificationMeta(
    'memoryTip',
  );
  @override
  late final GeneratedColumn<String> memoryTip = GeneratedColumn<String>(
    'memory_tip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _masteryMeta = const VerificationMeta(
    'mastery',
  );
  @override
  late final GeneratedColumn<int> mastery = GeneratedColumn<int>(
    'mastery',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapseCountMeta = const VerificationMeta(
    'lapseCount',
  );
  @override
  late final GeneratedColumn<int> lapseCount = GeneratedColumn<int>(
    'lapse_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<int> easeFactor = GeneratedColumn<int>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(250),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enrichmentStatusMeta = const VerificationMeta(
    'enrichmentStatus',
  );
  @override
  late final GeneratedColumn<String> enrichmentStatus = GeneratedColumn<String>(
    'enrichment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    remoteId,
    syncStatus,
    deletedAt,
    word,
    sourceType,
    bookKey,
    chineseMeaning,
    englishMeaning,
    greFocus,
    rootsJson,
    synonymsJson,
    antonymsJson,
    example,
    memoryTip,
    note,
    tagsJson,
    mastery,
    dueAt,
    reviewCount,
    lapseCount,
    easeFactor,
    intervalDays,
    enrichmentStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('book_key')) {
      context.handle(
        _bookKeyMeta,
        bookKey.isAcceptableOrUnknown(data['book_key']!, _bookKeyMeta),
      );
    }
    if (data.containsKey('chinese_meaning')) {
      context.handle(
        _chineseMeaningMeta,
        chineseMeaning.isAcceptableOrUnknown(
          data['chinese_meaning']!,
          _chineseMeaningMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chineseMeaningMeta);
    }
    if (data.containsKey('english_meaning')) {
      context.handle(
        _englishMeaningMeta,
        englishMeaning.isAcceptableOrUnknown(
          data['english_meaning']!,
          _englishMeaningMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_englishMeaningMeta);
    }
    if (data.containsKey('gre_focus')) {
      context.handle(
        _greFocusMeta,
        greFocus.isAcceptableOrUnknown(data['gre_focus']!, _greFocusMeta),
      );
    } else if (isInserting) {
      context.missing(_greFocusMeta);
    }
    if (data.containsKey('roots_json')) {
      context.handle(
        _rootsJsonMeta,
        rootsJson.isAcceptableOrUnknown(data['roots_json']!, _rootsJsonMeta),
      );
    }
    if (data.containsKey('synonyms_json')) {
      context.handle(
        _synonymsJsonMeta,
        synonymsJson.isAcceptableOrUnknown(
          data['synonyms_json']!,
          _synonymsJsonMeta,
        ),
      );
    }
    if (data.containsKey('antonyms_json')) {
      context.handle(
        _antonymsJsonMeta,
        antonymsJson.isAcceptableOrUnknown(
          data['antonyms_json']!,
          _antonymsJsonMeta,
        ),
      );
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    if (data.containsKey('memory_tip')) {
      context.handle(
        _memoryTipMeta,
        memoryTip.isAcceptableOrUnknown(data['memory_tip']!, _memoryTipMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('mastery')) {
      context.handle(
        _masteryMeta,
        mastery.isAcceptableOrUnknown(data['mastery']!, _masteryMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    if (data.containsKey('lapse_count')) {
      context.handle(
        _lapseCountMeta,
        lapseCount.isAcceptableOrUnknown(data['lapse_count']!, _lapseCountMeta),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('enrichment_status')) {
      context.handle(
        _enrichmentStatusMeta,
        enrichmentStatus.isAcceptableOrUnknown(
          data['enrichment_status']!,
          _enrichmentStatusMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      bookKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_key'],
      )!,
      chineseMeaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chinese_meaning'],
      )!,
      englishMeaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_meaning'],
      )!,
      greFocus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gre_focus'],
      )!,
      rootsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roots_json'],
      )!,
      synonymsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synonyms_json'],
      )!,
      antonymsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}antonyms_json'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      )!,
      memoryTip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memory_tip'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      mastery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      lapseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapse_count'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      enrichmentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enrichment_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WordCardsTable createAlias(String alias) {
    return $WordCardsTable(attachedDatabase, alias);
  }
}

class WordCard extends DataClass implements Insertable<WordCard> {
  final String id;
  final String userId;
  final String? remoteId;
  final String syncStatus;
  final DateTime? deletedAt;
  final String word;
  final String sourceType;
  final String bookKey;
  final String chineseMeaning;
  final String englishMeaning;
  final String greFocus;
  final String rootsJson;
  final String synonymsJson;
  final String antonymsJson;
  final String example;
  final String memoryTip;
  final String note;
  final String tagsJson;
  final int mastery;
  final DateTime dueAt;
  final int reviewCount;
  final int lapseCount;
  final int easeFactor;
  final int intervalDays;
  final String enrichmentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WordCard({
    required this.id,
    required this.userId,
    this.remoteId,
    required this.syncStatus,
    this.deletedAt,
    required this.word,
    required this.sourceType,
    required this.bookKey,
    required this.chineseMeaning,
    required this.englishMeaning,
    required this.greFocus,
    required this.rootsJson,
    required this.synonymsJson,
    required this.antonymsJson,
    required this.example,
    required this.memoryTip,
    required this.note,
    required this.tagsJson,
    required this.mastery,
    required this.dueAt,
    required this.reviewCount,
    required this.lapseCount,
    required this.easeFactor,
    required this.intervalDays,
    required this.enrichmentStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['word'] = Variable<String>(word);
    map['source_type'] = Variable<String>(sourceType);
    map['book_key'] = Variable<String>(bookKey);
    map['chinese_meaning'] = Variable<String>(chineseMeaning);
    map['english_meaning'] = Variable<String>(englishMeaning);
    map['gre_focus'] = Variable<String>(greFocus);
    map['roots_json'] = Variable<String>(rootsJson);
    map['synonyms_json'] = Variable<String>(synonymsJson);
    map['antonyms_json'] = Variable<String>(antonymsJson);
    map['example'] = Variable<String>(example);
    map['memory_tip'] = Variable<String>(memoryTip);
    map['note'] = Variable<String>(note);
    map['tags_json'] = Variable<String>(tagsJson);
    map['mastery'] = Variable<int>(mastery);
    map['due_at'] = Variable<DateTime>(dueAt);
    map['review_count'] = Variable<int>(reviewCount);
    map['lapse_count'] = Variable<int>(lapseCount);
    map['ease_factor'] = Variable<int>(easeFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['enrichment_status'] = Variable<String>(enrichmentStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WordCardsCompanion toCompanion(bool nullToAbsent) {
    return WordCardsCompanion(
      id: Value(id),
      userId: Value(userId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      syncStatus: Value(syncStatus),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      word: Value(word),
      sourceType: Value(sourceType),
      bookKey: Value(bookKey),
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
      mastery: Value(mastery),
      dueAt: Value(dueAt),
      reviewCount: Value(reviewCount),
      lapseCount: Value(lapseCount),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      enrichmentStatus: Value(enrichmentStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WordCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordCard(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      word: serializer.fromJson<String>(json['word']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      bookKey: serializer.fromJson<String>(json['bookKey']),
      chineseMeaning: serializer.fromJson<String>(json['chineseMeaning']),
      englishMeaning: serializer.fromJson<String>(json['englishMeaning']),
      greFocus: serializer.fromJson<String>(json['greFocus']),
      rootsJson: serializer.fromJson<String>(json['rootsJson']),
      synonymsJson: serializer.fromJson<String>(json['synonymsJson']),
      antonymsJson: serializer.fromJson<String>(json['antonymsJson']),
      example: serializer.fromJson<String>(json['example']),
      memoryTip: serializer.fromJson<String>(json['memoryTip']),
      note: serializer.fromJson<String>(json['note']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      mastery: serializer.fromJson<int>(json['mastery']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      lapseCount: serializer.fromJson<int>(json['lapseCount']),
      easeFactor: serializer.fromJson<int>(json['easeFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      enrichmentStatus: serializer.fromJson<String>(json['enrichmentStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'word': serializer.toJson<String>(word),
      'sourceType': serializer.toJson<String>(sourceType),
      'bookKey': serializer.toJson<String>(bookKey),
      'chineseMeaning': serializer.toJson<String>(chineseMeaning),
      'englishMeaning': serializer.toJson<String>(englishMeaning),
      'greFocus': serializer.toJson<String>(greFocus),
      'rootsJson': serializer.toJson<String>(rootsJson),
      'synonymsJson': serializer.toJson<String>(synonymsJson),
      'antonymsJson': serializer.toJson<String>(antonymsJson),
      'example': serializer.toJson<String>(example),
      'memoryTip': serializer.toJson<String>(memoryTip),
      'note': serializer.toJson<String>(note),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'mastery': serializer.toJson<int>(mastery),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'lapseCount': serializer.toJson<int>(lapseCount),
      'easeFactor': serializer.toJson<int>(easeFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'enrichmentStatus': serializer.toJson<String>(enrichmentStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WordCard copyWith({
    String? id,
    String? userId,
    Value<String?> remoteId = const Value.absent(),
    String? syncStatus,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? word,
    String? sourceType,
    String? bookKey,
    String? chineseMeaning,
    String? englishMeaning,
    String? greFocus,
    String? rootsJson,
    String? synonymsJson,
    String? antonymsJson,
    String? example,
    String? memoryTip,
    String? note,
    String? tagsJson,
    int? mastery,
    DateTime? dueAt,
    int? reviewCount,
    int? lapseCount,
    int? easeFactor,
    int? intervalDays,
    String? enrichmentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WordCard(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    syncStatus: syncStatus ?? this.syncStatus,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    word: word ?? this.word,
    sourceType: sourceType ?? this.sourceType,
    bookKey: bookKey ?? this.bookKey,
    chineseMeaning: chineseMeaning ?? this.chineseMeaning,
    englishMeaning: englishMeaning ?? this.englishMeaning,
    greFocus: greFocus ?? this.greFocus,
    rootsJson: rootsJson ?? this.rootsJson,
    synonymsJson: synonymsJson ?? this.synonymsJson,
    antonymsJson: antonymsJson ?? this.antonymsJson,
    example: example ?? this.example,
    memoryTip: memoryTip ?? this.memoryTip,
    note: note ?? this.note,
    tagsJson: tagsJson ?? this.tagsJson,
    mastery: mastery ?? this.mastery,
    dueAt: dueAt ?? this.dueAt,
    reviewCount: reviewCount ?? this.reviewCount,
    lapseCount: lapseCount ?? this.lapseCount,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    enrichmentStatus: enrichmentStatus ?? this.enrichmentStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WordCard copyWithCompanion(WordCardsCompanion data) {
    return WordCard(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      word: data.word.present ? data.word.value : this.word,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      bookKey: data.bookKey.present ? data.bookKey.value : this.bookKey,
      chineseMeaning: data.chineseMeaning.present
          ? data.chineseMeaning.value
          : this.chineseMeaning,
      englishMeaning: data.englishMeaning.present
          ? data.englishMeaning.value
          : this.englishMeaning,
      greFocus: data.greFocus.present ? data.greFocus.value : this.greFocus,
      rootsJson: data.rootsJson.present ? data.rootsJson.value : this.rootsJson,
      synonymsJson: data.synonymsJson.present
          ? data.synonymsJson.value
          : this.synonymsJson,
      antonymsJson: data.antonymsJson.present
          ? data.antonymsJson.value
          : this.antonymsJson,
      example: data.example.present ? data.example.value : this.example,
      memoryTip: data.memoryTip.present ? data.memoryTip.value : this.memoryTip,
      note: data.note.present ? data.note.value : this.note,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      mastery: data.mastery.present ? data.mastery.value : this.mastery,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      lapseCount: data.lapseCount.present
          ? data.lapseCount.value
          : this.lapseCount,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      enrichmentStatus: data.enrichmentStatus.present
          ? data.enrichmentStatus.value
          : this.enrichmentStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordCard(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('word: $word, ')
          ..write('sourceType: $sourceType, ')
          ..write('bookKey: $bookKey, ')
          ..write('chineseMeaning: $chineseMeaning, ')
          ..write('englishMeaning: $englishMeaning, ')
          ..write('greFocus: $greFocus, ')
          ..write('rootsJson: $rootsJson, ')
          ..write('synonymsJson: $synonymsJson, ')
          ..write('antonymsJson: $antonymsJson, ')
          ..write('example: $example, ')
          ..write('memoryTip: $memoryTip, ')
          ..write('note: $note, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('mastery: $mastery, ')
          ..write('dueAt: $dueAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('lapseCount: $lapseCount, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('enrichmentStatus: $enrichmentStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    remoteId,
    syncStatus,
    deletedAt,
    word,
    sourceType,
    bookKey,
    chineseMeaning,
    englishMeaning,
    greFocus,
    rootsJson,
    synonymsJson,
    antonymsJson,
    example,
    memoryTip,
    note,
    tagsJson,
    mastery,
    dueAt,
    reviewCount,
    lapseCount,
    easeFactor,
    intervalDays,
    enrichmentStatus,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordCard &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.remoteId == this.remoteId &&
          other.syncStatus == this.syncStatus &&
          other.deletedAt == this.deletedAt &&
          other.word == this.word &&
          other.sourceType == this.sourceType &&
          other.bookKey == this.bookKey &&
          other.chineseMeaning == this.chineseMeaning &&
          other.englishMeaning == this.englishMeaning &&
          other.greFocus == this.greFocus &&
          other.rootsJson == this.rootsJson &&
          other.synonymsJson == this.synonymsJson &&
          other.antonymsJson == this.antonymsJson &&
          other.example == this.example &&
          other.memoryTip == this.memoryTip &&
          other.note == this.note &&
          other.tagsJson == this.tagsJson &&
          other.mastery == this.mastery &&
          other.dueAt == this.dueAt &&
          other.reviewCount == this.reviewCount &&
          other.lapseCount == this.lapseCount &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.enrichmentStatus == this.enrichmentStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WordCardsCompanion extends UpdateCompanion<WordCard> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> remoteId;
  final Value<String> syncStatus;
  final Value<DateTime?> deletedAt;
  final Value<String> word;
  final Value<String> sourceType;
  final Value<String> bookKey;
  final Value<String> chineseMeaning;
  final Value<String> englishMeaning;
  final Value<String> greFocus;
  final Value<String> rootsJson;
  final Value<String> synonymsJson;
  final Value<String> antonymsJson;
  final Value<String> example;
  final Value<String> memoryTip;
  final Value<String> note;
  final Value<String> tagsJson;
  final Value<int> mastery;
  final Value<DateTime> dueAt;
  final Value<int> reviewCount;
  final Value<int> lapseCount;
  final Value<int> easeFactor;
  final Value<int> intervalDays;
  final Value<String> enrichmentStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WordCardsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.word = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.bookKey = const Value.absent(),
    this.chineseMeaning = const Value.absent(),
    this.englishMeaning = const Value.absent(),
    this.greFocus = const Value.absent(),
    this.rootsJson = const Value.absent(),
    this.synonymsJson = const Value.absent(),
    this.antonymsJson = const Value.absent(),
    this.example = const Value.absent(),
    this.memoryTip = const Value.absent(),
    this.note = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.mastery = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.lapseCount = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.enrichmentStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordCardsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String word,
    this.sourceType = const Value.absent(),
    this.bookKey = const Value.absent(),
    required String chineseMeaning,
    required String englishMeaning,
    required String greFocus,
    this.rootsJson = const Value.absent(),
    this.synonymsJson = const Value.absent(),
    this.antonymsJson = const Value.absent(),
    this.example = const Value.absent(),
    this.memoryTip = const Value.absent(),
    this.note = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.mastery = const Value.absent(),
    required DateTime dueAt,
    this.reviewCount = const Value.absent(),
    this.lapseCount = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.enrichmentStatus = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       word = Value(word),
       chineseMeaning = Value(chineseMeaning),
       englishMeaning = Value(englishMeaning),
       greFocus = Value(greFocus),
       dueAt = Value(dueAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WordCard> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? remoteId,
    Expression<String>? syncStatus,
    Expression<DateTime>? deletedAt,
    Expression<String>? word,
    Expression<String>? sourceType,
    Expression<String>? bookKey,
    Expression<String>? chineseMeaning,
    Expression<String>? englishMeaning,
    Expression<String>? greFocus,
    Expression<String>? rootsJson,
    Expression<String>? synonymsJson,
    Expression<String>? antonymsJson,
    Expression<String>? example,
    Expression<String>? memoryTip,
    Expression<String>? note,
    Expression<String>? tagsJson,
    Expression<int>? mastery,
    Expression<DateTime>? dueAt,
    Expression<int>? reviewCount,
    Expression<int>? lapseCount,
    Expression<int>? easeFactor,
    Expression<int>? intervalDays,
    Expression<String>? enrichmentStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (remoteId != null) 'remote_id': remoteId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (word != null) 'word': word,
      if (sourceType != null) 'source_type': sourceType,
      if (bookKey != null) 'book_key': bookKey,
      if (chineseMeaning != null) 'chinese_meaning': chineseMeaning,
      if (englishMeaning != null) 'english_meaning': englishMeaning,
      if (greFocus != null) 'gre_focus': greFocus,
      if (rootsJson != null) 'roots_json': rootsJson,
      if (synonymsJson != null) 'synonyms_json': synonymsJson,
      if (antonymsJson != null) 'antonyms_json': antonymsJson,
      if (example != null) 'example': example,
      if (memoryTip != null) 'memory_tip': memoryTip,
      if (note != null) 'note': note,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (mastery != null) 'mastery': mastery,
      if (dueAt != null) 'due_at': dueAt,
      if (reviewCount != null) 'review_count': reviewCount,
      if (lapseCount != null) 'lapse_count': lapseCount,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (enrichmentStatus != null) 'enrichment_status': enrichmentStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? remoteId,
    Value<String>? syncStatus,
    Value<DateTime?>? deletedAt,
    Value<String>? word,
    Value<String>? sourceType,
    Value<String>? bookKey,
    Value<String>? chineseMeaning,
    Value<String>? englishMeaning,
    Value<String>? greFocus,
    Value<String>? rootsJson,
    Value<String>? synonymsJson,
    Value<String>? antonymsJson,
    Value<String>? example,
    Value<String>? memoryTip,
    Value<String>? note,
    Value<String>? tagsJson,
    Value<int>? mastery,
    Value<DateTime>? dueAt,
    Value<int>? reviewCount,
    Value<int>? lapseCount,
    Value<int>? easeFactor,
    Value<int>? intervalDays,
    Value<String>? enrichmentStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WordCardsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      remoteId: remoteId ?? this.remoteId,
      syncStatus: syncStatus ?? this.syncStatus,
      deletedAt: deletedAt ?? this.deletedAt,
      word: word ?? this.word,
      sourceType: sourceType ?? this.sourceType,
      bookKey: bookKey ?? this.bookKey,
      chineseMeaning: chineseMeaning ?? this.chineseMeaning,
      englishMeaning: englishMeaning ?? this.englishMeaning,
      greFocus: greFocus ?? this.greFocus,
      rootsJson: rootsJson ?? this.rootsJson,
      synonymsJson: synonymsJson ?? this.synonymsJson,
      antonymsJson: antonymsJson ?? this.antonymsJson,
      example: example ?? this.example,
      memoryTip: memoryTip ?? this.memoryTip,
      note: note ?? this.note,
      tagsJson: tagsJson ?? this.tagsJson,
      mastery: mastery ?? this.mastery,
      dueAt: dueAt ?? this.dueAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lapseCount: lapseCount ?? this.lapseCount,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      enrichmentStatus: enrichmentStatus ?? this.enrichmentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (bookKey.present) {
      map['book_key'] = Variable<String>(bookKey.value);
    }
    if (chineseMeaning.present) {
      map['chinese_meaning'] = Variable<String>(chineseMeaning.value);
    }
    if (englishMeaning.present) {
      map['english_meaning'] = Variable<String>(englishMeaning.value);
    }
    if (greFocus.present) {
      map['gre_focus'] = Variable<String>(greFocus.value);
    }
    if (rootsJson.present) {
      map['roots_json'] = Variable<String>(rootsJson.value);
    }
    if (synonymsJson.present) {
      map['synonyms_json'] = Variable<String>(synonymsJson.value);
    }
    if (antonymsJson.present) {
      map['antonyms_json'] = Variable<String>(antonymsJson.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (memoryTip.present) {
      map['memory_tip'] = Variable<String>(memoryTip.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (mastery.present) {
      map['mastery'] = Variable<int>(mastery.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (lapseCount.present) {
      map['lapse_count'] = Variable<int>(lapseCount.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<int>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (enrichmentStatus.present) {
      map['enrichment_status'] = Variable<String>(enrichmentStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordCardsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('word: $word, ')
          ..write('sourceType: $sourceType, ')
          ..write('bookKey: $bookKey, ')
          ..write('chineseMeaning: $chineseMeaning, ')
          ..write('englishMeaning: $englishMeaning, ')
          ..write('greFocus: $greFocus, ')
          ..write('rootsJson: $rootsJson, ')
          ..write('synonymsJson: $synonymsJson, ')
          ..write('antonymsJson: $antonymsJson, ')
          ..write('example: $example, ')
          ..write('memoryTip: $memoryTip, ')
          ..write('note: $note, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('mastery: $mastery, ')
          ..write('dueAt: $dueAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('lapseCount: $lapseCount, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('enrichmentStatus: $enrichmentStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_legacy'),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dirty'),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES word_cards (id)',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    remoteId,
    syncStatus,
    deletedAt,
    wordId,
    rating,
    reviewedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final int id;
  final String userId;
  final String? remoteId;
  final String syncStatus;
  final DateTime? deletedAt;
  final String wordId;
  final String rating;
  final DateTime reviewedAt;
  final DateTime? updatedAt;
  const ReviewLog({
    required this.id,
    required this.userId,
    this.remoteId,
    required this.syncStatus,
    this.deletedAt,
    required this.wordId,
    required this.rating,
    required this.reviewedAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['word_id'] = Variable<String>(wordId);
    map['rating'] = Variable<String>(rating);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      userId: Value(userId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      syncStatus: Value(syncStatus),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      wordId: Value(wordId),
      rating: Value(rating),
      reviewedAt: Value(reviewedAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      wordId: serializer.fromJson<String>(json['wordId']),
      rating: serializer.fromJson<String>(json['rating']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'wordId': serializer.toJson<String>(wordId),
      'rating': serializer.toJson<String>(rating),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  ReviewLog copyWith({
    int? id,
    String? userId,
    Value<String?> remoteId = const Value.absent(),
    String? syncStatus,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? wordId,
    String? rating,
    DateTime? reviewedAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => ReviewLog(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    syncStatus: syncStatus ?? this.syncStatus,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    wordId: wordId ?? this.wordId,
    rating: rating ?? this.rating,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('wordId: $wordId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    remoteId,
    syncStatus,
    deletedAt,
    wordId,
    rating,
    reviewedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.remoteId == this.remoteId &&
          other.syncStatus == this.syncStatus &&
          other.deletedAt == this.deletedAt &&
          other.wordId == this.wordId &&
          other.rating == this.rating &&
          other.reviewedAt == this.reviewedAt &&
          other.updatedAt == this.updatedAt);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String?> remoteId;
  final Value<String> syncStatus;
  final Value<DateTime?> deletedAt;
  final Value<String> wordId;
  final Value<String> rating;
  final Value<DateTime> reviewedAt;
  final Value<DateTime?> updatedAt;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.wordId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String wordId,
    required String rating,
    required DateTime reviewedAt,
    this.updatedAt = const Value.absent(),
  }) : wordId = Value(wordId),
       rating = Value(rating),
       reviewedAt = Value(reviewedAt);
  static Insertable<ReviewLog> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? remoteId,
    Expression<String>? syncStatus,
    Expression<DateTime>? deletedAt,
    Expression<String>? wordId,
    Expression<String>? rating,
    Expression<DateTime>? reviewedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (remoteId != null) 'remote_id': remoteId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (wordId != null) 'word_id': wordId,
      if (rating != null) 'rating': rating,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String?>? remoteId,
    Value<String>? syncStatus,
    Value<DateTime?>? deletedAt,
    Value<String>? wordId,
    Value<String>? rating,
    Value<DateTime>? reviewedAt,
    Value<DateTime?>? updatedAt,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      remoteId: remoteId ?? this.remoteId,
      syncStatus: syncStatus ?? this.syncStatus,
      deletedAt: deletedAt ?? this.deletedAt,
      wordId: wordId ?? this.wordId,
      rating: rating ?? this.rating,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('wordId: $wordId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordCardsTable wordCards = $WordCardsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [wordCards, reviewLogs];
}

typedef $$WordCardsTableCreateCompanionBuilder =
    WordCardsCompanion Function({
      required String id,
      Value<String> userId,
      Value<String?> remoteId,
      Value<String> syncStatus,
      Value<DateTime?> deletedAt,
      required String word,
      Value<String> sourceType,
      Value<String> bookKey,
      required String chineseMeaning,
      required String englishMeaning,
      required String greFocus,
      Value<String> rootsJson,
      Value<String> synonymsJson,
      Value<String> antonymsJson,
      Value<String> example,
      Value<String> memoryTip,
      Value<String> note,
      Value<String> tagsJson,
      Value<int> mastery,
      required DateTime dueAt,
      Value<int> reviewCount,
      Value<int> lapseCount,
      Value<int> easeFactor,
      Value<int> intervalDays,
      Value<String> enrichmentStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WordCardsTableUpdateCompanionBuilder =
    WordCardsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> remoteId,
      Value<String> syncStatus,
      Value<DateTime?> deletedAt,
      Value<String> word,
      Value<String> sourceType,
      Value<String> bookKey,
      Value<String> chineseMeaning,
      Value<String> englishMeaning,
      Value<String> greFocus,
      Value<String> rootsJson,
      Value<String> synonymsJson,
      Value<String> antonymsJson,
      Value<String> example,
      Value<String> memoryTip,
      Value<String> note,
      Value<String> tagsJson,
      Value<int> mastery,
      Value<DateTime> dueAt,
      Value<int> reviewCount,
      Value<int> lapseCount,
      Value<int> easeFactor,
      Value<int> intervalDays,
      Value<String> enrichmentStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$WordCardsTableReferences
    extends BaseReferences<_$AppDatabase, $WordCardsTable, WordCard> {
  $$WordCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLog>>
  _reviewLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewLogs,
    aliasName: $_aliasNameGenerator(db.wordCards.id, db.reviewLogs.wordId),
  );

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager(
      $_db,
      $_db.reviewLogs,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordCardsTableFilterComposer
    extends Composer<_$AppDatabase, $WordCardsTable> {
  $$WordCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookKey => $composableBuilder(
    column: $table.bookKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chineseMeaning => $composableBuilder(
    column: $table.chineseMeaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishMeaning => $composableBuilder(
    column: $table.englishMeaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get greFocus => $composableBuilder(
    column: $table.greFocus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootsJson => $composableBuilder(
    column: $table.rootsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get synonymsJson => $composableBuilder(
    column: $table.synonymsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get antonymsJson => $composableBuilder(
    column: $table.antonymsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memoryTip => $composableBuilder(
    column: $table.memoryTip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mastery => $composableBuilder(
    column: $table.mastery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enrichmentStatus => $composableBuilder(
    column: $table.enrichmentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> reviewLogsRefs(
    Expression<bool> Function($$ReviewLogsTableFilterComposer f) f,
  ) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableFilterComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordCardsTable> {
  $$WordCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookKey => $composableBuilder(
    column: $table.bookKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chineseMeaning => $composableBuilder(
    column: $table.chineseMeaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishMeaning => $composableBuilder(
    column: $table.englishMeaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get greFocus => $composableBuilder(
    column: $table.greFocus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootsJson => $composableBuilder(
    column: $table.rootsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get synonymsJson => $composableBuilder(
    column: $table.synonymsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get antonymsJson => $composableBuilder(
    column: $table.antonymsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memoryTip => $composableBuilder(
    column: $table.memoryTip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mastery => $composableBuilder(
    column: $table.mastery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enrichmentStatus => $composableBuilder(
    column: $table.enrichmentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordCardsTable> {
  $$WordCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookKey =>
      $composableBuilder(column: $table.bookKey, builder: (column) => column);

  GeneratedColumn<String> get chineseMeaning => $composableBuilder(
    column: $table.chineseMeaning,
    builder: (column) => column,
  );

  GeneratedColumn<String> get englishMeaning => $composableBuilder(
    column: $table.englishMeaning,
    builder: (column) => column,
  );

  GeneratedColumn<String> get greFocus =>
      $composableBuilder(column: $table.greFocus, builder: (column) => column);

  GeneratedColumn<String> get rootsJson =>
      $composableBuilder(column: $table.rootsJson, builder: (column) => column);

  GeneratedColumn<String> get synonymsJson => $composableBuilder(
    column: $table.synonymsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get antonymsJson => $composableBuilder(
    column: $table.antonymsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get memoryTip =>
      $composableBuilder(column: $table.memoryTip, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<int> get mastery =>
      $composableBuilder(column: $table.mastery, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enrichmentStatus => $composableBuilder(
    column: $table.enrichmentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> reviewLogsRefs<T extends Object>(
    Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f,
  ) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordCardsTable,
          WordCard,
          $$WordCardsTableFilterComposer,
          $$WordCardsTableOrderingComposer,
          $$WordCardsTableAnnotationComposer,
          $$WordCardsTableCreateCompanionBuilder,
          $$WordCardsTableUpdateCompanionBuilder,
          (WordCard, $$WordCardsTableReferences),
          WordCard,
          PrefetchHooks Function({bool reviewLogsRefs})
        > {
  $$WordCardsTableTableManager(_$AppDatabase db, $WordCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> bookKey = const Value.absent(),
                Value<String> chineseMeaning = const Value.absent(),
                Value<String> englishMeaning = const Value.absent(),
                Value<String> greFocus = const Value.absent(),
                Value<String> rootsJson = const Value.absent(),
                Value<String> synonymsJson = const Value.absent(),
                Value<String> antonymsJson = const Value.absent(),
                Value<String> example = const Value.absent(),
                Value<String> memoryTip = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<int> mastery = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> lapseCount = const Value.absent(),
                Value<int> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<String> enrichmentStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordCardsCompanion(
                id: id,
                userId: userId,
                remoteId: remoteId,
                syncStatus: syncStatus,
                deletedAt: deletedAt,
                word: word,
                sourceType: sourceType,
                bookKey: bookKey,
                chineseMeaning: chineseMeaning,
                englishMeaning: englishMeaning,
                greFocus: greFocus,
                rootsJson: rootsJson,
                synonymsJson: synonymsJson,
                antonymsJson: antonymsJson,
                example: example,
                memoryTip: memoryTip,
                note: note,
                tagsJson: tagsJson,
                mastery: mastery,
                dueAt: dueAt,
                reviewCount: reviewCount,
                lapseCount: lapseCount,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                enrichmentStatus: enrichmentStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> userId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String word,
                Value<String> sourceType = const Value.absent(),
                Value<String> bookKey = const Value.absent(),
                required String chineseMeaning,
                required String englishMeaning,
                required String greFocus,
                Value<String> rootsJson = const Value.absent(),
                Value<String> synonymsJson = const Value.absent(),
                Value<String> antonymsJson = const Value.absent(),
                Value<String> example = const Value.absent(),
                Value<String> memoryTip = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<int> mastery = const Value.absent(),
                required DateTime dueAt,
                Value<int> reviewCount = const Value.absent(),
                Value<int> lapseCount = const Value.absent(),
                Value<int> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<String> enrichmentStatus = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WordCardsCompanion.insert(
                id: id,
                userId: userId,
                remoteId: remoteId,
                syncStatus: syncStatus,
                deletedAt: deletedAt,
                word: word,
                sourceType: sourceType,
                bookKey: bookKey,
                chineseMeaning: chineseMeaning,
                englishMeaning: englishMeaning,
                greFocus: greFocus,
                rootsJson: rootsJson,
                synonymsJson: synonymsJson,
                antonymsJson: antonymsJson,
                example: example,
                memoryTip: memoryTip,
                note: note,
                tagsJson: tagsJson,
                mastery: mastery,
                dueAt: dueAt,
                reviewCount: reviewCount,
                lapseCount: lapseCount,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                enrichmentStatus: enrichmentStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WordCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({reviewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (reviewLogsRefs) db.reviewLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (reviewLogsRefs)
                    await $_getPrefetchedData<
                      WordCard,
                      $WordCardsTable,
                      ReviewLog
                    >(
                      currentTable: table,
                      referencedTable: $$WordCardsTableReferences
                          ._reviewLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WordCardsTableReferences(
                            db,
                            table,
                            p0,
                          ).reviewLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.wordId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WordCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordCardsTable,
      WordCard,
      $$WordCardsTableFilterComposer,
      $$WordCardsTableOrderingComposer,
      $$WordCardsTableAnnotationComposer,
      $$WordCardsTableCreateCompanionBuilder,
      $$WordCardsTableUpdateCompanionBuilder,
      (WordCard, $$WordCardsTableReferences),
      WordCard,
      PrefetchHooks Function({bool reviewLogsRefs})
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String?> remoteId,
      Value<String> syncStatus,
      Value<DateTime?> deletedAt,
      required String wordId,
      required String rating,
      required DateTime reviewedAt,
      Value<DateTime?> updatedAt,
    });
typedef $$ReviewLogsTableUpdateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String?> remoteId,
      Value<String> syncStatus,
      Value<DateTime?> deletedAt,
      Value<String> wordId,
      Value<String> rating,
      Value<DateTime> reviewedAt,
      Value<DateTime?> updatedAt,
    });

final class $$ReviewLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog> {
  $$ReviewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordCardsTable _wordIdTable(_$AppDatabase db) => db.wordCards
      .createAlias($_aliasNameGenerator(db.reviewLogs.wordId, db.wordCards.id));

  $$WordCardsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<String>('word_id')!;

    final manager = $$WordCardsTableTableManager(
      $_db,
      $_db.wordCards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WordCardsTableFilterComposer get wordId {
    final $$WordCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.wordCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordCardsTableFilterComposer(
            $db: $db,
            $table: $db.wordCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordCardsTableOrderingComposer get wordId {
    final $$WordCardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.wordCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordCardsTableOrderingComposer(
            $db: $db,
            $table: $db.wordCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WordCardsTableAnnotationComposer get wordId {
    final $$WordCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.wordCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.wordCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogsTable,
          ReviewLog,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (ReviewLog, $$ReviewLogsTableReferences),
          ReviewLog,
          PrefetchHooks Function({bool wordId})
        > {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> wordId = const Value.absent(),
                Value<String> rating = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                userId: userId,
                remoteId: remoteId,
                syncStatus: syncStatus,
                deletedAt: deletedAt,
                wordId: wordId,
                rating: rating,
                reviewedAt: reviewedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String wordId,
                required String rating,
                required DateTime reviewedAt,
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => ReviewLogsCompanion.insert(
                id: id,
                userId: userId,
                remoteId: remoteId,
                syncStatus: syncStatus,
                deletedAt: deletedAt,
                wordId: wordId,
                rating: rating,
                reviewedAt: reviewedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$ReviewLogsTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$ReviewLogsTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogsTable,
      ReviewLog,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (ReviewLog, $$ReviewLogsTableReferences),
      ReviewLog,
      PrefetchHooks Function({bool wordId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordCardsTableTableManager get wordCards =>
      $$WordCardsTableTableManager(_db, _db.wordCards);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
}
