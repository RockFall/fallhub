/// Per-object interaction feedback categories (MD 10 R30).
enum ObjectFeedbackKind {
  switchClick,
  bookPage,
  keyboardTick,
  boardgamePiece,
  cupClink,
  softThud,
  silent,
}

abstract final class ObjectFeedbackCatalog {
  static ObjectFeedbackKind forTags(Set<String> tags) {
    if (tags.contains('switch') || tags.contains('light')) {
      return ObjectFeedbackKind.switchClick;
    }
    if (tags.contains('book')) return ObjectFeedbackKind.bookPage;
    if (tags.contains('keyboard') || tags.contains('laptop')) {
      return ObjectFeedbackKind.keyboardTick;
    }
    if (tags.contains('boardgame') || tags.contains('game')) {
      return ObjectFeedbackKind.boardgamePiece;
    }
    if (tags.contains('cup') || tags.contains('mug')) {
      return ObjectFeedbackKind.cupClink;
    }
    if (tags.contains('furniture')) return ObjectFeedbackKind.softThud;
    return ObjectFeedbackKind.silent;
  }

  static String moteLabel(ObjectFeedbackKind k) => switch (k) {
        ObjectFeedbackKind.switchClick => 'click',
        ObjectFeedbackKind.bookPage => '…página',
        ObjectFeedbackKind.keyboardTick => 'tak',
        ObjectFeedbackKind.boardgamePiece => 'clac',
        ObjectFeedbackKind.cupClink => 'cling',
        ObjectFeedbackKind.softThud => 'thud',
        ObjectFeedbackKind.silent => '',
      };
}
