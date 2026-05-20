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
  WordBookDefinition(
    key: 'life',
    label: '生活英语词书',
    shortLabel: '生活',
    description: '覆盖租房、购物、通勤、预约和日常事务词汇。',
    tags: ['life'],
  ),
  WordBookDefinition(
    key: 'economics',
    label: '经济专业词书',
    shortLabel: '经济',
    description: '覆盖宏微观经济、金融市场、贸易和商业语境词汇。',
    tags: ['economics'],
  ),
  WordBookDefinition(
    key: 'math',
    label: '数学专业词书',
    shortLabel: '数学',
    description: '覆盖微积分、统计、代数和常见数学表达。',
    tags: ['math'],
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
