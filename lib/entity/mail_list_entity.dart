/// 通讯录实体
class MailListEntity {
  String phone = '';
  String zone = '';
  String name = '';
  String uid = '';
  String vercode = '';
  int isFriend = 0;

  MailListEntity();

  MailListEntity.fromMap(Map<String, dynamic> map) {
    phone = map['phone'] ?? '';
    zone = map['zone'] ?? '';
    name = map['name'] ?? '';
    uid = map['uid'] ?? '';
    vercode = map['vercode'] ?? '';
    isFriend = map['is_friend'] ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'zone': zone,
      'name': name,
      'uid': uid,
      'vercode': vercode,
      'is_friend': isFriend,
    };
  }
}
