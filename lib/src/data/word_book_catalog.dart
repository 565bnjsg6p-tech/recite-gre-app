class WordBookDefinition {
  const WordBookDefinition({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.tags,
    this.comingSoon = false,
  });

  final String key;
  final String label;
  final String shortLabel;
  final String description;
  final List<String> tags;
  final bool comingSoon;

  bool matchesTags(Iterable<String> sourceTags) {
    final normalized = sourceTags.map((item) => item.toLowerCase()).toSet();
    return tags.any(normalized.contains);
  }
}

const wordBookCatalog = <WordBookDefinition>[
  WordBookDefinition(
    key: 'gre',
    label: 'GRE 词书',
    shortLabel: 'GRE',
    description: '偏高频学术词，适合写作和阅读提升。',
    tags: ['gre'],
  ),
  WordBookDefinition(
    key: 'ielts',
    label: '雅思词书',
    shortLabel: 'IELTS',
    description: '覆盖雅思常见阅读、听力和写作词汇。',
    tags: ['ielts'],
  ),
  WordBookDefinition(
    key: 'toefl',
    label: '托福词书',
    shortLabel: 'TOEFL',
    description: '适合托福阅读与学术语境词汇。',
    tags: ['toefl'],
  ),
  WordBookDefinition(
    key: 'cet4',
    label: '四级词书',
    shortLabel: 'CET4',
    description: '大学英语四级常用词汇。',
    tags: ['cet4'],
  ),
  WordBookDefinition(
    key: 'cet6',
    label: '六级词书',
    shortLabel: 'CET6',
    description: '大学英语六级高频词汇。',
    tags: ['cet6'],
  ),
];

WordBookDefinition? findWordBook(String key) {
  for (final book in wordBookCatalog) {
    if (book.key == key) {
      return book;
    }
  }
  return null;
}
