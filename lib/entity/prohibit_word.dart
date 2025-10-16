/// 敏感词实体
class ProhibitWord {
  int id = 0;
  String content = '';
  int isDeleted = 0;
  int version = 0;
  String createdAt = '';

  ProhibitWord();

  ProhibitWord.fromMap(Map<String, dynamic> map) {
    id = map['sid'] ?? 0;
    content = map['content'] ?? '';
    isDeleted = map['is_deleted'] ?? 0;
    version = map['version'] ?? 0;
    createdAt = map['created_at'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'sid': id,
      'content': content,
      'is_deleted': isDeleted,
      'version': version,
      'created_at': createdAt,
    };
  }
}
