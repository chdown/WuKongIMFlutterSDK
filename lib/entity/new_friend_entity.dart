/// 2019-12-05 15:21
/// 好友申请实体
class NewFriendEntity {
  String applyUid = '';
  String applyName = '';
  String token = '';
  int status = 0;
  String remark = '';
  String createdAt = '';

  NewFriendEntity();

  NewFriendEntity.fromMap(Map<String, dynamic> map) {
    applyUid = map['apply_uid'] ?? '';
    applyName = map['apply_name'] ?? '';
    token = map['token'] ?? '';
    status = map['status'] ?? 0;
    remark = map['remark'] ?? '';
    createdAt = map['created_at'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'apply_uid': applyUid,
      'apply_name': applyName,
      'token': token,
      'status': status,
      'remark': remark,
      'created_at': createdAt,
    };
  }
}
