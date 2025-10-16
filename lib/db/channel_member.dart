import 'package:sqflite/sqflite.dart';

import '../entity/channel_member.dart';
import 'const.dart';
import 'wk_db_helper.dart';

class ChannelMemberDB {
  ChannelMemberDB._privateConstructor();

  static final ChannelMemberDB _instance = ChannelMemberDB._privateConstructor();

  static ChannelMemberDB get shared => _instance;
  final String channelCols =
      "${WKDBConst.tableChannel}.channel_remark,${WKDBConst.tableChannel}.channel_name,${WKDBConst.tableChannel}.avatar,${WKDBConst.tableChannel}.avatar_cache_key";

  Future<List<WKChannelMember>> queryMemberWithUIDs(String channelID, int channelType, List<String> uidList) async {
    List<Object> args = [];
    args.add(channelID);
    args.add(channelType);
    args.addAll(uidList);
    List<WKChannelMember> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.query(WKDBConst.tableChannelMember,
        where: "channel_id=? and channel_type=? and member_uid in (${WKDBConst.getPlaceholders(uidList.length)})", whereArgs: args);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeChannelMember(data));
      }
    }
    return list;
  }

  Future<int> getMaxVersion(String channelID, int channelType) async {
    String sql = "select max(version) version from ${WKDBConst.tableChannelMember} where channel_id =? and channel_type=? limit 0, 1";
    int version = 0;
    if (WKDBHelper.shared.getDB() == null) {
      return version;
    }
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelID, channelType]);
    if (results.isNotEmpty) {
      dynamic data = results[0];
      version = WKDBConst.readInt(data, 'version');
    }
    return version;
  }

  Future<WKChannelMember?> queryWithUID(String channelId, int channelType, String memberUID) async {
    String sql =
        "select ${WKDBConst.tableChannelMember}.*,$channelCols from ${WKDBConst.tableChannelMember} left join ${WKDBConst.tableChannel} on ${WKDBConst.tableChannelMember}.member_uid = ${WKDBConst.tableChannel}.channel_id AND ${WKDBConst.tableChannel}.channel_type=1 where (${WKDBConst.tableChannelMember}.channel_id=? and ${WKDBConst.tableChannelMember}.channel_type=? and ${WKDBConst.tableChannelMember}.member_uid=?)";
    WKChannelMember? channelMember;
    if (WKDBHelper.shared.getDB() == null) {
      return channelMember;
    }
    List<Map<String, Object?>> list = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelId, channelType, memberUID]);
    if (list.isNotEmpty) {
      channelMember = WKDBConst.serializeChannelMember(list[0]);
    }
    return channelMember;
  }

  Future<List<WKChannelMember>?> queryWithChannel(String channelId, int channelType) async {
    String sql =
        "select ${WKDBConst.tableChannelMember}.*,$channelCols from ${WKDBConst.tableChannelMember} LEFT JOIN ${WKDBConst.tableChannel} on ${WKDBConst.tableChannelMember}.member_uid=${WKDBConst.tableChannel}.channel_id and ${WKDBConst.tableChannel}.channel_type=1 where ${WKDBConst.tableChannelMember}.channel_id=? and ${WKDBConst.tableChannelMember}.channel_type=? and ${WKDBConst.tableChannelMember}.is_deleted=0 and ${WKDBConst.tableChannelMember}.status=1 order by ${WKDBConst.tableChannelMember}.role=1 desc,${WKDBConst.tableChannelMember}.role=2 desc,${WKDBConst.tableChannelMember}.created_at asc";
    List<WKChannelMember> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelId, channelType]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeChannelMember(data));
      }
    }
    return list;
  }

  Future<List<WKChannelMember>> queryWithUIDs(String channelID, int channelType, List<String> uidList) async {
    List<Object> args = [];
    args.add(channelID);
    args.add(channelType);
    args.addAll(uidList);

    List<WKChannelMember> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.query(WKDBConst.tableChannelMember,
        where: "channel_id=? and channel_type=? and member_uid in (${WKDBConst.getPlaceholders(uidList.length)}) ", whereArgs: args);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeChannelMember(data));
      }
    }
    return list;
  }

  insertList(List<WKChannelMember> allMemberList) {
    if (WKDBHelper.shared.getDB() == null) {
      return;
    }
    List<Map<String, Object>> insertCVList = [];
    for (WKChannelMember channelMember in allMemberList) {
      insertCVList.add(getMap(channelMember));
    }
    if (insertCVList.isNotEmpty) {
      WKDBHelper.shared.getDB()!.transaction((txn) async {
        if (insertCVList.isNotEmpty) {
          for (Map<String, dynamic> value in insertCVList) {
            txn.insert(WKDBConst.tableChannelMember, value, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });
    }
  }

  dynamic getMap(WKChannelMember member) {
    var map = <String, Object>{};
    map['channel_id'] = member.channelID;
    map['channel_type'] = member.channelType;
    map['member_invite_uid'] = member.memberInviteUID;
    map['member_uid'] = member.memberUID;
    map['member_name'] = member.memberName;
    map['member_remark'] = member.memberRemark;
    map['member_avatar'] = member.memberAvatar;
    map['member_avatar_cache_key'] = member.memberAvatarCacheKey;
    map['role'] = member.role;
    map['is_deleted'] = member.isDeleted;
    map['version'] = member.version;
    map['status'] = member.status;
    map['robot'] = member.robot;
    map['forbidden_expiration_time'] = member.forbiddenExpirationTime;
    map['created_at'] = member.createdAt;
    map['updated_at'] = member.updatedAt;
    map['extra'] = member.extraMap?.toString() ?? "";
    return map;
  }

  // ========== 新增的缺失方法 ==========

  /// 分页查询成员
  Future<List<WKChannelMember>> queryWithPage(String channelId, int channelType, int page, int size) async {
    List<WKChannelMember> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    int offset = (page - 1) * size;
    String sql = "SELECT * FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=? AND is_deleted=0 ORDER BY created_at DESC LIMIT ?,?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelId, channelType, offset, size]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKChannelMember(data));
      }
    }
    return list;
  }

  /// 查询所有成员
  Future<List<WKChannelMember>> query(String channelId, int channelType) async {
    List<WKChannelMember> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=? AND is_deleted=0 ORDER BY created_at DESC";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelId, channelType]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKChannelMember(data));
      }
    }
    return list;
  }

  /// 查询已删除成员
  Future<List<WKChannelMember>> queryDeleted(String channelId, int channelType) async {
    List<WKChannelMember> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=? AND is_deleted=1 ORDER BY created_at DESC";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelId, channelType]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKChannelMember(data));
      }
    }
    return list;
  }

  /// 查询最大版本号
  Future<int> queryMaxVersion(String channelID, int channelType) async {
    if (WKDBHelper.shared.getDB() == null) {
      return 0;
    }
    String sql = "SELECT MAX(version) as max_version FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelID, channelType]);
    if (results.isNotEmpty) {
      return WKDBConst.readInt(results.first, 'max_version');
    }
    return 0;
  }

  /// 查询最大版本成员
  Future<WKChannelMember?> queryMaxVersionMember(String channelID, int channelType) async {
    if (WKDBHelper.shared.getDB() == null) {
      return null;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=? ORDER BY version DESC LIMIT 1";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelID, channelType]);
    if (results.isNotEmpty) {
      return WKDBConst.serializeWKChannelMember(results.first);
    }
    return null;
  }

  /// 查询机器人成员
  Future<List<WKChannelMember>> queryRobotMembers(String channelId, int channelType) async {
    List<WKChannelMember> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=? AND robot=1 AND is_deleted=0 ORDER BY created_at DESC";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelId, channelType]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKChannelMember(data));
      }
    }
    return list;
  }

  /// 按角色查询成员
  Future<List<WKChannelMember>> queryWithRole(String channelId, int channelType, int role) async {
    List<WKChannelMember> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=? AND role=? AND is_deleted=0 ORDER BY created_at DESC";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelId, channelType, role]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKChannelMember(data));
      }
    }
    return list;
  }

  /// 按状态查询成员
  Future<List<WKChannelMember>> queryWithStatus(String channelId, int channelType, int status) async {
    List<WKChannelMember> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=? AND status=? AND is_deleted=0 ORDER BY created_at DESC";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelId, channelType, status]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKChannelMember(data));
      }
    }
    return list;
  }

  /// 查询成员数量
  Future<int> queryCount(String channelID, int channelType) async {
    if (WKDBHelper.shared.getDB() == null) {
      return 0;
    }
    String sql = "SELECT COUNT(*) as count FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=? AND is_deleted=0";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelID, channelType]);
    if (results.isNotEmpty) {
      return WKDBConst.readInt(results.first, 'count');
    }
    return 0;
  }

  /// 搜索成员
  Future<List<WKChannelMember>> search(String channelId, int channelType, String keyword, int page, int size) async {
    List<WKChannelMember> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    int offset = (page - 1) * size;
    String sql =
        "SELECT * FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=? AND is_deleted=0 AND (member_name LIKE ? OR member_remark LIKE ?) ORDER BY created_at DESC LIMIT ?,?";
    String searchKey = "%$keyword%";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelId, channelType, searchKey, searchKey, offset, size]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKChannelMember(data));
      }
    }
    return list;
  }

  /// 插入单个成员
  Future<bool> insert(WKChannelMember member) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    await WKDBHelper.shared.getDB()!.insert(WKDBConst.tableChannelMember, getMap(member), conflictAlgorithm: ConflictAlgorithm.replace);
    return true;
  }

  /// 批量插入成员
  Future<bool> insertMembers(List<WKChannelMember> list) async {
    if (WKDBHelper.shared.getDB() == null || list.isEmpty) {
      return false;
    }
    List<Map<String, Object>> cvList = [];
    for (WKChannelMember member in list) {
      cvList.add(getMap(member));
    }
    await WKDBHelper.shared.getDB()!.transaction((txn) async {
      for (int i = 0; i < cvList.length; i++) {
        txn.insert(WKDBConst.tableChannelMember, cvList[i], conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return true;
  }

  /// 插入或更新成员
  Future<bool> insertOrUpdate(WKChannelMember member) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    await WKDBHelper.shared.getDB()!.insert(WKDBConst.tableChannelMember, getMap(member), conflictAlgorithm: ConflictAlgorithm.replace);
    return true;
  }

  /// 更新成员
  Future<bool> update(WKChannelMember member) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    int result = await WKDBHelper.shared.getDB()!.update(
      WKDBConst.tableChannelMember,
      getMap(member),
      where: "channel_id=? AND channel_type=? AND member_uid=?",
      whereArgs: [member.channelID, member.channelType, member.memberUID],
    );
    return result > 0;
  }

  /// 更新成员字段
  Future<bool> updateWithField(String channelID, int channelType, String uid, String field, String value) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    int result = await WKDBHelper.shared.getDB()!.update(
          WKDBConst.tableChannelMember,
          {field: value},
          where: "channel_id=? AND channel_type=? AND member_uid=?",
          whereArgs: [channelID, channelType, uid],
        );
    return result > 0;
  }

  /// 按频道删除成员
  Future<bool> deleteWithChannel(String channelID, int channelType) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    int result = await WKDBHelper.shared.getDB()!.delete(
      WKDBConst.tableChannelMember,
      where: "channel_id=? AND channel_type=?",
      whereArgs: [channelID, channelType],
    );
    return result > 0;
  }

  /// 删除成员列表
  Future<bool> deleteMembers(List<WKChannelMember> list) async {
    if (WKDBHelper.shared.getDB() == null || list.isEmpty) {
      return false;
    }
    List<String> uids = [];
    for (WKChannelMember member in list) {
      uids.add(member.memberUID);
    }
    String sql = "DELETE FROM ${WKDBConst.tableChannelMember} WHERE member_uid IN (${WKDBConst.getPlaceholders(uids.length)})";
    await WKDBHelper.shared.getDB()!.rawQuery(sql, uids);
    return true;
  }

  // ========== 补充缺失的方法 ==========

  /// 检查成员是否存在
  Future<bool> isExist(String channelId, int channelType, String uid) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    String sql = "SELECT COUNT(*) as count FROM ${WKDBConst.tableChannelMember} WHERE channel_id=? AND channel_type=? AND member_uid=?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelId, channelType, uid]);
    if (results.isNotEmpty) {
      return WKDBConst.readInt(results.first, 'count') > 0;
    }
    return false;
  }
}
