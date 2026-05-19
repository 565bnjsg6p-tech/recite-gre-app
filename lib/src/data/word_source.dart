enum WordSourceKind { personal, book }

extension WordSourceKindX on WordSourceKind {
  String get dbValue => name;

  String get label => switch (this) {
    WordSourceKind.personal => '个人词',
    WordSourceKind.book => '词书词',
  };
}

WordSourceKind wordSourceKindFromDb(String value) {
  return value == WordSourceKind.book.name
      ? WordSourceKind.book
      : WordSourceKind.personal;
}

