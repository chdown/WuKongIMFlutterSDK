import '../entity/mail_list_entity.dart';
import 'wk_db_helper.dart';
import 'const.dart';

/// 通讯录管理
class WKContactsDB {
  WKContactsDB._privateConstructor();
  static final WKContactsDB _instance = WKContactsDB._privateConstructor();
  static WKContactsDB get instance => _instance;

  /// 查询所有联系人
  Future<List<MailListEntity>> query() async {
    List<MailListEntity> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }

    String sql = "SELECT * FROM user_contact";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(serialize(data));
      }
    }
    return list;
  }

  /// 序列化联系人
  MailListEntity serialize(Map<String, Object?> data) {
    MailListEntity entity = MailListEntity();
    entity.phone = WKDBConst.readString(data, 'phone');
    entity.zone = WKDBConst.readString(data, 'zone');
    entity.name = WKDBConst.readString(data, 'name');
    entity.uid = WKDBConst.readString(data, 'uid');
    entity.vercode = WKDBConst.readString(data, 'vercode');
    entity.isFriend = WKDBConst.readInt(data, 'is_friend');
    return entity;
  }

  /// 保存联系人列表
  Future<void> save(List<MailListEntity> list) async {
    if (list.isEmpty) return;

    try {
      await WKDBHelper.shared.getDB()!.transaction((txn) async {
        for (MailListEntity entity in list) {
          bool isAdd = true;
          if (await isExist(entity)) {
            isAdd = await delete(entity);
          }
          if (isAdd) {
            await txn.insert('user_contact', getMap(entity));
          }
        }
      });
    } catch (e) {
      // 处理异常
    }
  }

  /// 删除联系人
  Future<bool> delete(MailListEntity entity) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }

    int result = await WKDBHelper.shared.getDB()!.delete('user_contact', where: 'phone=? AND name=?', whereArgs: [entity.phone, entity.name]);
    return result > 0;
  }

  /// 更新好友状态
  Future<void> updateFriendStatus(String uid, int isFriend) async {
    if (WKDBHelper.shared.getDB() == null) return;

    Map<String, Object> contentValues = {'is_friend': isFriend};
    await WKDBHelper.shared.getDB()!.update('user_contact', contentValues, where: 'uid=?', whereArgs: [uid]);
  }

  /// 插入联系人
  Future<void> insert(MailListEntity entity) async {
    if (WKDBHelper.shared.getDB() == null) return;

    await WKDBHelper.shared.getDB()!.insert('user_contact', getMap(entity));
  }

  /// 检查联系人是否存在
  Future<bool> isExist(MailListEntity entity) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }

    String sql = "SELECT * FROM user_contact WHERE phone=? AND name=?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [entity.phone, entity.name]);
    return results.isNotEmpty;
  }

  /// 获取ContentValues
  Map<String, Object> getMap(MailListEntity entity) {
    return {
      'phone': entity.phone,
      'uid': entity.uid,
      'zone': entity.zone,
      'name': entity.name,
      'vercode': entity.vercode,
      'is_friend': entity.isFriend,
    };
  }
}
