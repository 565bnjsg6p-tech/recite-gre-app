enum MasteryLevel { newWord, learning, familiar, mastered }

class RootPart {
  const RootPart({required this.part, required this.meaning});

  final String part;
  final String meaning;
}

class WordEntry {
  const WordEntry({
    required this.id,
    required this.word,
    required this.createdAtMs,
    required this.chineseMeaning,
    required this.englishMeaning,
    required this.greFocus,
    required this.roots,
    required this.synonyms,
    required this.antonyms,
    required this.example,
    required this.memoryTip,
    required this.note,
    required this.tags,
    required this.mastery,
    required this.dueLabel,
    required this.reviewCount,
    required this.lapseCount,
    required this.easeFactor,
    required this.intervalDays,
    required this.enrichmentStatus,
  });

  final String id;
  final String word;
  final int createdAtMs;
  final String chineseMeaning;
  final String englishMeaning;
  final String greFocus;
  final List<RootPart> roots;
  final List<String> synonyms;
  final List<String> antonyms;
  final String example;
  final String memoryTip;
  final String note;
  final List<String> tags;
  final MasteryLevel mastery;
  final String dueLabel;
  final int reviewCount;
  final int lapseCount;
  final int easeFactor;
  final int intervalDays;
  final String enrichmentStatus;
}

class StudyPlan {
  const StudyPlan({
    required this.dailyNewWords,
    required this.dailyReviewLimit,
    required this.examDateLabel,
    required this.todayNewDone,
    required this.todayReviewDone,
    required this.streakDays,
  });

  final int dailyNewWords;
  final int dailyReviewLimit;
  final String examDateLabel;
  final int todayNewDone;
  final int todayReviewDone;
  final int streakDays;
}
