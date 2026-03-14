class NoteComment {
  final int _a, _b;
  final DateTime createdAt;

  const NoteComment({
    required int on,
    required int comment,
    required this.createdAt,
  }) : _a = on,
       _b = comment;

  int get parentId => _a;
  int get commentId => _b;
}
