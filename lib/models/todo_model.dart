class TodoModel {
  final String id;
  final String task;
  final String extraNote;
  final bool complete;

  TodoModel({
    required this.id,
    required this.task,
    required this.extraNote,
    required this.complete,
  });

  // ✅ For Firebase
  factory TodoModel.fromMap(Map<String, dynamic> data, String documentId) {
    String task = data['task'] ?? '';
    String extraNote = data['extraNote'] ?? '';

    // ✅ Handle if 'complete' is stored as int (0/1) or bool
    final rawComplete = data['complete'];
    bool complete = (rawComplete is bool) ? rawComplete : rawComplete == 1;

    return TodoModel(
      id: documentId,
      task: task,
      extraNote: extraNote,
      complete: complete,
    );
  }

  // ✅ For Firebase
  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'extraNote': extraNote,
      'complete': complete,
    };
  }

  // ✅ For SQLite
  factory TodoModel.fromSqliteMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'],
      task: map['task'],
      extraNote: map['extraNote'],
      complete: map['complete'] == 1, // SQLite stores bool as int (0/1)
    );
  }

  // ✅ For SQLite
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'task': task,
      'extraNote': extraNote,
      'complete': complete ? 1 : 0,
    };
  }
}
