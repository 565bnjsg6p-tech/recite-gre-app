import 'word_entry.dart';

class AiContentQuality {
  const AiContentQuality({
    required this.score,
    required this.missingRequired,
    required this.warnings,
  });

  final int score;
  final List<String> missingRequired;
  final List<String> warnings;

  bool get isAcceptable => score >= 80 && missingRequired.isEmpty;

  String get summary {
    if (isAcceptable) {
      return 'AI 内容完整度 $score 分。';
    }
    final missing = missingRequired.isEmpty
        ? '内容完整度偏低'
        : '缺少 ${missingRequired.join('、')}';
    return 'AI 内容需复核：$missing，当前 $score 分。';
  }
}

AiContentQuality evaluateAiContent({
  required String chineseMeaning,
  required String englishMeaning,
  required String greFocus,
  required List<RootPart> roots,
  required List<String> synonyms,
  required List<String> antonyms,
  required String example,
  required String memoryTip,
  required List<String> tags,
}) {
  var score = 0;
  final missing = <String>[];
  final warnings = <String>[];

  void awardText({
    required String label,
    required String value,
    required int weight,
    required int minLength,
    bool required = true,
  }) {
    if (_usefulText(value, minLength)) {
      score += weight;
      return;
    }
    if (required) {
      missing.add(label);
    } else {
      warnings.add('$label偏少');
    }
  }

  awardText(label: '中文释义', value: chineseMeaning, weight: 15, minLength: 6);
  awardText(label: '英文释义', value: englishMeaning, weight: 10, minLength: 12);
  awardText(label: 'GRE 考点', value: greFocus, weight: 20, minLength: 18);
  if (roots.any(
    (root) => _usefulText(root.part, 1) && _usefulText(root.meaning, 1),
  )) {
    score += 15;
  } else {
    missing.add('词根词缀');
  }
  if (synonyms.where((item) => _usefulText(item, 2)).length >= 2) {
    score += 10;
  } else {
    missing.add('同义词');
  }
  awardText(label: '例句', value: example, weight: 15, minLength: 20);
  awardText(label: '记忆提示', value: memoryTip, weight: 15, minLength: 10);

  if (antonyms.where((item) => _usefulText(item, 2)).isEmpty) {
    warnings.add('反义词为空');
  }
  if (tags.where((item) => _usefulText(item, 1)).length < 2) {
    warnings.add('标签偏少');
  }

  return AiContentQuality(
    score: score.clamp(0, 100).toInt(),
    missingRequired: List.unmodifiable(missing),
    warnings: List.unmodifiable(warnings),
  );
}

AiContentQuality evaluateWordEntryQuality(WordEntry word) {
  return evaluateAiContent(
    chineseMeaning: word.chineseMeaning,
    englishMeaning: word.englishMeaning,
    greFocus: word.greFocus,
    roots: word.roots,
    synonyms: word.synonyms,
    antonyms: word.antonyms,
    example: word.example,
    memoryTip: word.memoryTip,
    tags: word.tags,
  );
}

bool _usefulText(String value, int minLength) {
  final trimmed = value.trim();
  if (trimmed.length < minLength) {
    return false;
  }
  const placeholders = [
    '暂无',
    '待补全',
    '待 AI',
    '基础词典补全',
    '等待 AI',
    '无',
    'none',
    'n/a',
  ];
  final lower = trimmed.toLowerCase();
  return !placeholders.any(lower.contains);
}
