import '../entity/new_friend_entity.dart';
import 'wk_db_helper.dart';
import 'const.dart';

/// 2019-12-05 15:21
/// 好友申请管理
class ApplyDB {
  ApplyDB._privateConstructor();
  static final ApplyDB _instance = ApplyDB._privateConstructor();
  static ApplyDB get instance => _instance;

  static const String tableName = 'apply_tab';

  /// 查询所有申请
  Future<List<NewFriendEntity>> queryAll() async {
    List<NewFriendEntity> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }

    String sql = "SELECT * FROM $tableName ORDER BY created_at DESC";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(serializeFriend(data));
      }
    }
    return list;
  }

  /// 查询单个申请
  Future<NewFriendEntity?> query(String applyUid) async {
    if (WKDBHelper.shared.getDB() == null) {
      return null;
    }

    String sql = "SELECT * FROM $tableName WHERE apply_uid=?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [applyUid]);
    if (results.isNotEmpty) {
      return serializeFriend(results.first);
    }
    return null;
  }

  /// 插入申请
  Future<int> insert(NewFriendEntity friendEntity) async {
    if (WKDBHelper.shared.getDB() == null) {
      return -1;
    }

    try {
      Map<String, Object> cv = getMap(friendEntity);
      return await WKDBHelper.shared.getDB()!.insert(tableName, cv);
    } catch (e) {
      return -1;
    }
  }

  /// 批量保存
  Future<void> insertList(List<NewFriendEntity> list) async {
    if (list.isEmpty) return;

    try {
      await WKDBHelper.shared.getDB()!.transaction((txn) async {
        for (NewFriendEntity entity in list) {
          await txn.insert(tableName, getMap(entity));
        }
      });
    } catch (e) {
      // 处理异常
    }
  }

  /// 更新申请
  Future<bool> update(NewFriendEntity friendEntity) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }

    try {
      Map<String, Object> cv = getMap(friendEntity);
      int result = await WKDBHelper.shared.getDB()!.update(tableName, cv, where: 'apply_uid=?', whereArgs: [friendEntity.applyUid]);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  /// 删除申请
  Future<void> delete(String uid) async {
    if (WKDBHelper.shared.getDB() == null) return;

    await WKDBHelper.shared.getDB()!.delete(tableName, where: 'apply_uid=?', whereArgs: [uid]);
  }

  /// 序列化好友申请
  NewFriendEntity serializeFriend(Map<String, Object?> data) {
    NewFriendEntity friendEntity = NewFriendEntity();
    friendEntity.applyUid = WKDBConst.readString(data, 'apply_uid');
    friendEntity.applyName = WKDBConst.readString(data, 'apply_name');
    friendEntity.token = WKDBConst.readString(data, 'token');
    friendEntity.status = WKDBConst.readInt(data, 'status');
    friendEntity.remark = WKDBConst.readString(data, 'remark');
    friendEntity.createdAt = WKDBConst.readString(data, 'created_at');
    return friendEntity;
  }

  /// 获取ContentValues
  Map<String, Object> getMap(NewFriendEntity friendEntity) {
    return {
      'apply_uid': friendEntity.applyUid,
      'apply_name': friendEntity.applyName,
      'token': friendEntity.token,
      'status': friendEntity.status,
      'remark': friendEntity.remark,
      'created_at': friendEntity.createdAt,
    };
  }
}
