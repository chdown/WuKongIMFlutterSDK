import 'dart:collection';

import 'package:sqflite/sqflite.dart';
import 'package:wukongimfluttersdk/common/logs.dart';
import 'package:wukongimfluttersdk/db/channel.dart';
import 'package:wukongimfluttersdk/db/const.dart';
import 'package:wukongimfluttersdk/entity/channel.dart';

import '../entity/conversation.dart';
import 'wk_db_helper.dart';

class ConversationDB {
  ConversationDB._privateConstructor();
  static final ConversationDB _instance = ConversationDB._privateConstructor();
  static ConversationDB get shared => _instance;
  final String extraCols =
      "IFNULL(${WKDBConst.tableConversationExtra}.browse_to,0) AS browse_to,IFNULL(${WKDBConst.tableConversationExtra}.keep_message_seq,0) AS keep_message_seq,IFNULL(${WKDBConst.tableConversationExtra}.keep_offset_y,0) AS keep_offset_y,IFNULL(${WKDBConst.tableConversationExtra}.draft,'') AS draft,IFNULL(${WKDBConst.tableConversationExtra}.draft_updated_at,0) AS draft_updated_at,IFNULL(${WKDBConst.tableConversationExtra}.version,0) AS extra_version";
  final String channelCols =
      "${WKDBConst.tableChannel}.channel_remark,${WKDBConst.tableChannel}.channel_name,${WKDBConst.tableChannel}.top,${WKDBConst.tableChannel}.mute,${WKDBConst.tableChannel}.save,${WKDBConst.tableChannel}.status as channel_status,${WKDBConst.tableChannel}.forbidden,${WKDBConst.tableChannel}.invite,${WKDBConst.tableChannel}.follow,${WKDBConst.tableChannel}.is_deleted as channel_is_deleted,${WKDBConst.tableChannel}.show_nick,${WKDBConst.tableChannel}.avatar,${WKDBConst.tableChannel}.avatar_cache_key,${WKDBConst.tableChannel}.online,${WKDBConst.tableChannel}.last_offline,${WKDBConst.tableChannel}.category,${WKDBConst.tableChannel}.receipt,${WKDBConst.tableChannel}.robot,${WKDBConst.tableChannel}.parent_channel_id AS c_parent_channel_id,${WKDBConst.tableChannel}.parent_channel_type AS c_parent_channel_type,${WKDBConst.tableChannel}.version AS channel_version,${WKDBConst.tableChannel}.remote_extra AS channel_remote_extra,${WKDBConst.tableChannel}.extra AS channel_extra";

  Future<List<WKUIConversationMsg>> queryAll() async {
    String sql =
        "SELECT ${WKDBConst.tableConversation}.*,$channelCols,$extraCols FROM ${WKDBConst.tableConversation} LEFT JOIN ${WKDBConst.tableChannel} ON ${WKDBConst.tableConversation}.channel_id = ${WKDBConst.tableChannel}.channel_id AND ${WKDBConst.tableConversation}.channel_type = ${WKDBConst.tableChannel}.channel_type LEFT JOIN ${WKDBConst.tableConversationExtra} ON ${WKDBConst.tableConversation}.channel_id=${WKDBConst.tableConversationExtra}.channel_id AND ${WKDBConst.tableConversation}.channel_type=${WKDBConst.tableConversationExtra}.channel_type where ${WKDBConst.tableConversation}.is_deleted=0 order by last_msg_timestamp desc";
    List<WKUIConversationMsg> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        WKConversationMsg msg = WKDBConst.serializeCoversation(data);
        WKChannel wkChannel = WKDBConst.serializeChannel(data);
        wkChannel.remoteExtraMap = WKDBConst.readDynamic(data, 'channel_remote_extra');
        wkChannel.localExtra = WKDBConst.readDynamic(data, 'channel_extra');
        WKUIConversationMsg uiMsg = getUIMsg(msg);
        uiMsg.setWkChannel(wkChannel);
        list.add(uiMsg);
      }
    }
    return list;
  }

  Future<bool> delete(String channelID, int channelType) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    Map<String, dynamic> data = HashMap<String, Object>();
    data['is_deleted'] = 1;
    int row = await WKDBHelper.shared
        .getDB()!
        .update(WKDBConst.tableConversation, data, where: "channel_id=? and channel_type=?", whereArgs: [channelID, channelType]);
    return row > 0;
  }

  Future<WKUIConversationMsg?> insertOrUpdateWithConvMsg(WKConversationMsg conversationMsg) async {
    if (WKDBHelper.shared.getDB() == null) {
      return null;
    }
    int row;
    WKConversationMsg? lastMsg = await queryMsgByMsgChannelId(conversationMsg.channelID, conversationMsg.channelType);

    if (lastMsg == null || lastMsg.channelID.isEmpty) {
      row = await WKDBHelper.shared.getDB()!.insert(WKDBConst.tableConversation, getMap(conversationMsg, false), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      // 这里有错误数据，需要清理
      var len = lastMsg.localExtraMap?.toString().length ?? 0;
      if (len < 1000000) {
        conversationMsg.localExtraMap ??= lastMsg.localExtraMap;
      }
      conversationMsg.unreadCount = lastMsg.unreadCount + conversationMsg.unreadCount;
      row = await WKDBHelper.shared.getDB()!.update(WKDBConst.tableConversation, getMap(conversationMsg, false),
          where: "channel_id=? and channel_type=?", whereArgs: [conversationMsg.channelID, conversationMsg.channelType]);
    }
    if (row > 0) {
      return getUIMsg(conversationMsg);
    }
    return null;
  }

  Future<WKConversationMsg?> queryMsgByMsgChannelId(String channelId, int channelType) async {
    WKConversationMsg? msg;
    if (WKDBHelper.shared.getDB() == null) {
      return msg;
    }
    List<Map<String, Object?>> list =
        await WKDBHelper.shared.getDB()!.query(WKDBConst.tableConversation, where: "channel_id=? and channel_type=?", whereArgs: [channelId, channelType]);
    if (list.isNotEmpty) {
      msg = WKDBConst.serializeCoversation(list[0]);
    }
    return msg;
  }

  Future<int> queryAllUnreadCount() async {
    int count = 0;
    var channels = await ChannelDB.shared.queryWithMuted();
    var channelIds = [];
    var sql = "";
    List<Map<String, Object?>>? list;
    if (channels.isNotEmpty) {
      for (var channel in channels) {
        channelIds.add(channel.channelID);
      }
      sql = "select SUM(unread_count) count from ${WKDBConst.tableConversation} where channel_id not in (${WKDBConst.getPlaceholders(channelIds.length)})";
      list = await WKDBHelper.shared.getDB()!.rawQuery(sql, channelIds);
    } else {
      sql = "select SUM(unread_count) count from ${WKDBConst.tableConversation}";
      list = await WKDBHelper.shared.getDB()?.rawQuery(sql);
    }
    if (list == null || list.isEmpty) {
      return count;
    }
    dynamic data = list[0];
    count = WKDBConst.readInt(data, 'count');
    Logs.error('总数量$count');
    return count;
  }

  Future<int> getMaxVersion() async {
    int maxVersion = 0;
    if (WKDBHelper.shared.getDB() == null) {
      return maxVersion;
    }
    String sql = "select max(version) version from ${WKDBConst.tableConversation} limit 0, 1";

    List<Map<String, Object?>> list = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      maxVersion = WKDBConst.readInt(data, 'version');
    }
    return maxVersion;
  }

  Future<String> getLastMsgSeqs() async {
    String lastMsgSeqs = "";
    if (WKDBHelper.shared.getDB() == null) {
      return lastMsgSeqs;
    }
    String sql =
        "select GROUP_CONCAT(channel_id||':'||channel_type||':'|| last_seq,'|') synckey from (select *,(select max(message_seq) from ${WKDBConst.tableMessage} where ${WKDBConst.tableMessage}.channel_id=${WKDBConst.tableConversation}.channel_id and ${WKDBConst.tableMessage}.channel_type=${WKDBConst.tableConversation}.channel_type limit 1) last_seq from ${WKDBConst.tableConversation}) cn where channel_id<>'' AND is_deleted=0";

    List<Map<String, Object?>> list = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      lastMsgSeqs = WKDBConst.readString(data, 'synckey');
    }
    return lastMsgSeqs;
  }

  Future<List<WKConversationMsg>> queryWithChannelIds(List<String> channelIds) async {
    List<WKConversationMsg> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    List<Map<String, Object?>> results = await WKDBHelper.shared
        .getDB()!
        .query(WKDBConst.tableConversation, where: "channel_id in (${WKDBConst.getPlaceholders(channelIds.length)})", whereArgs: channelIds);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeCoversation(data));
      }
    }
    return list;
  }

  insetMsgs(List<WKConversationMsg> list) async {
    if (WKDBHelper.shared.getDB() == null) {
      return;
    }
    List<Map<String, dynamic>> insertList = [];
    for (WKConversationMsg msg in list) {
      insertList.add(getMap(msg, true));
    }
    WKDBHelper.shared.getDB()!.transaction((txn) async {
      if (insertList.isNotEmpty) {
        for (int i = 0; i < insertList.length; i++) {
          txn.insert(WKDBConst.tableConversation, insertList[i], conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  insertMsgList(List<WKConversationMsg> list) async {
    if (WKDBHelper.shared.getDB() == null) {
      return;
    }
    List<String> channelIds = [];
    for (var i = 0; i < list.length; i++) {
      if (list[i].channelID != '') {
        channelIds.add(list[i].channelID);
      }
    }
    List<WKConversationMsg> existList = await queryWithChannelIds(channelIds);
    List<Map<String, dynamic>> insertList = [];
    List<Map<String, dynamic>> updateList = [];

    for (WKConversationMsg msg in list) {
      bool isAdd = true;
      if (existList.isNotEmpty) {
        for (var i = 0; i < existList.length; i++) {
          if (existList[i].channelID == msg.channelID && existList[i].channelType == msg.channelType) {
            updateList.add(getMap(msg, true));
            isAdd = false;
            break;
          }
        }
      }
      if (isAdd) {
        insertList.add(getMap(msg, true));
      }
    }
    if (insertList.isNotEmpty || updateList.isNotEmpty) {
      WKDBHelper.shared.getDB()!.transaction((txn) async {
        if (insertList.isNotEmpty) {
          for (int i = 0; i < insertList.length; i++) {
            txn.insert(WKDBConst.tableConversation, insertList[i], conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (updateList.isNotEmpty) {
          for (Map<String, dynamic> value in updateList) {
            txn.update(WKDBConst.tableConversation, value, where: "channel_id=? and channel_type=?", whereArgs: [value['channel_id'], value['channel_type']]);
          }
        }
      });
    }
  }

  clearAll() {
    if (WKDBHelper.shared.getDB() == null) {
      return;
    }
    WKDBHelper.shared.getDB()!.delete(WKDBConst.tableConversation);
  }

  Future<int> queryExtraMaxVersion() async {
    int maxVersion = 0;
    if (WKDBHelper.shared.getDB() == null) {
      return maxVersion;
    }
    String sql = "select max(version) version from ${WKDBConst.tableConversationExtra}";

    List<Map<String, Object?>> list = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      maxVersion = WKDBConst.readInt(data, 'version');
    }
    return maxVersion;
  }

  Future<int> clearAllRedDot() async {
    if (WKDBHelper.shared.getDB() == null) {
      return 0;
    }
    var map = <String, Object>{};

    map['unread_count'] = 0;
    return await WKDBHelper.shared.getDB()!.update(WKDBConst.tableConversation, map, where: "unread_count>0");
  }

  Future<int> updateWithField(dynamic map, String channelID, int channelType) async {
    if (WKDBHelper.shared.getDB() == null) {
      return 0;
    }
    return await WKDBHelper.shared
        .getDB()!
        .update(WKDBConst.tableConversation, map, where: "channel_id=? and channel_type=?", whereArgs: [channelID, channelType]);
  }

  WKUIConversationMsg getUIMsg(WKConversationMsg conversationMsg) {
    WKUIConversationMsg msg = WKUIConversationMsg();
    msg.lastMsgSeq = conversationMsg.lastMsgSeq;
    msg.clientMsgNo = conversationMsg.lastClientMsgNO;
    msg.unreadCount = conversationMsg.unreadCount;
    msg.lastMsgTimestamp = conversationMsg.lastMsgTimestamp;
    msg.channelID = conversationMsg.channelID;
    msg.channelType = conversationMsg.channelType;
    msg.isDeleted = conversationMsg.isDeleted;
    msg.localExtraMap = conversationMsg.localExtraMap;
    msg.parentChannelID = conversationMsg.parentChannelID;
    msg.parentChannelType = conversationMsg.parentChannelType;
    msg.setRemoteMsgExtra(conversationMsg.msgExtra);
    return msg;
  }

  Map<String, dynamic> getMap(WKConversationMsg msg, bool isSync) {
    Map<String, dynamic> data = HashMap<String, Object>();
    data['channel_id'] = msg.channelID;
    data['channel_type'] = msg.channelType;
    data['last_client_msg_no'] = msg.lastClientMsgNO;
    data['last_msg_timestamp'] = msg.lastMsgTimestamp;
    data['last_msg_seq'] = msg.lastMsgSeq;
    data['unread_count'] = msg.unreadCount;
    data['parent_channel_id'] = msg.parentChannelID;
    data['parent_channel_type'] = msg.parentChannelType;
    data['is_deleted'] = msg.isDeleted;
    data['extra'] = msg.localExtraMap?.toString() ?? "";
    if (isSync) {
      data['version'] = msg.version;
    }
    return data;
  }

  // ========== 新增的缺失方法 ==========

  /// 按频道类型查询会话
  Future<List<WKConversationMsg>> queryWithChannelType(int channelType) async {
    List<WKConversationMsg> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableConversation} WHERE channel_type=? AND is_deleted=0 ORDER BY last_msg_timestamp DESC";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelType]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKConversationMsg(data));
      }
    }
    return list;
  }

  /// 查询最大版本号
  Future<int> queryMaxVersion() async {
    if (WKDBHelper.shared.getDB() == null) {
      return 0;
    }
    String sql = "SELECT MAX(version) as max_version FROM ${WKDBConst.tableConversation}";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (results.isNotEmpty) {
      return WKDBConst.readInt(results.first, 'max_version');
    }
    return 0;
  }

  /// 查询最后消息序号
  Future<String> queryLastMsgSeqs() async {
    if (WKDBHelper.shared.getDB() == null) {
      return "";
    }
    String sql = "SELECT last_msg_seq FROM ${WKDBConst.tableConversation} WHERE is_deleted=0 ORDER BY last_msg_timestamp DESC";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    List<String> seqs = [];
    for (Map<String, Object?> data in results) {
      int seq = WKDBConst.readInt(data, 'last_msg_seq');
      if (seq > 0) {
        seqs.add(seq.toString());
      }
    }
    return seqs.join(',');
  }

  /// 按频道查询会话
  Future<WKConversationMsg?> queryWithChannel(String channelID, int channelType) async {
    if (WKDBHelper.shared.getDB() == null) {
      return null;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableConversation} WHERE channel_id=? AND channel_type=?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelID, channelType]);
    if (results.isNotEmpty) {
      return WKDBConst.serializeWKConversationMsg(results.first);
    }
    return null;
  }

  /// 查询会话扩展信息
  Future<WKConversationMsgExtra?> queryMsgExtraWithChannel(String channelID, int channelType) async {
    if (WKDBHelper.shared.getDB() == null) {
      return null;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableConversationExtra} WHERE channel_id=? AND channel_type=?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [channelID, channelType]);
    if (results.isNotEmpty) {
      return WKDBConst.serializeWKConversationMsgExtra(results.first);
    }
    return null;
  }

  /// 查询会话扩展最大版本
  Future<int> queryMsgExtraMaxVersion() async {
    if (WKDBHelper.shared.getDB() == null) {
      return 0;
    }
    String sql = "SELECT MAX(version) as max_version FROM ${WKDBConst.tableConversationExtra}";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (results.isNotEmpty) {
      return WKDBConst.readInt(results.first, 'max_version');
    }
    return 0;
  }

  // ========== 补充缺失的方法 ==========

  /// 插入同步消息
  Future<bool> insertSyncMsg(Map<String, dynamic> cv) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    await WKDBHelper.shared.getDB()!.insert(WKDBConst.tableConversation, cv, conflictAlgorithm: ConflictAlgorithm.replace);
    return true;
  }

  /// 更新红点状态
  Future<bool> updateRedDot(String channelID, int channelType, int redDot) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    int result = await WKDBHelper.shared.getDB()!.update(
          WKDBConst.tableConversation,
          {'unread_count': redDot},
          where: "channel_id=? AND channel_type=?",
          whereArgs: [channelID, channelType],
        );
    return result > 0;
  }

  /// 更新消息
  Future<bool> updateMsg(String channelID, int channelType, String clientMsgNo, int lastMsgSeq, int count) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    int result = await WKDBHelper.shared.getDB()!.update(
          WKDBConst.tableConversation,
          {
            'last_client_msg_no': clientMsgNo,
            'last_msg_seq': lastMsgSeq,
            'unread_count': count,
          },
          where: "channel_id=? AND channel_type=?",
          whereArgs: [channelID, channelType],
        );
    return result > 0;
  }

  /// 插入或更新会话(带消息)
  Future<WKUIConversationMsg?> insertOrUpdateWithMsg(dynamic msg, int unreadCount) async {
    if (WKDBHelper.shared.getDB() == null) {
      return null;
    }
    WKConversationMsg conversationMsg = WKConversationMsg();
    conversationMsg.channelID = msg.channelID;
    conversationMsg.channelType = msg.channelType;
    conversationMsg.lastClientMsgNO = msg.clientMsgNO;
    conversationMsg.lastMsgTimestamp = msg.timestamp;
    conversationMsg.lastMsgSeq = msg.messageSeq;
    conversationMsg.unreadCount = unreadCount;
    conversationMsg.isDeleted = 0;

    await WKDBHelper.shared.getDB()!.insert(
          WKDBConst.tableConversation,
          getMap(conversationMsg, false),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

    return getUIMsg(conversationMsg);
  }

  /// 插入或更新会话扩展
  Future<bool> insertOrUpdateMsgExtra(WKConversationMsgExtra extra) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    await WKDBHelper.shared.getDB()!.insert(
          WKDBConst.tableConversationExtra,
          getExtraMap(extra),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
    return true;
  }

  /// 插入会话扩展列表
  Future<bool> insertMsgExtras(List<WKConversationMsgExtra> list) async {
    if (WKDBHelper.shared.getDB() == null || list.isEmpty) {
      return false;
    }
    List<Map<String, Object>> cvList = [];
    for (WKConversationMsgExtra extra in list) {
      cvList.add(getExtraMap(extra));
    }
    await WKDBHelper.shared.getDB()!.transaction((txn) async {
      for (int i = 0; i < cvList.length; i++) {
        txn.insert(WKDBConst.tableConversationExtra, cvList[i], conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return true;
  }

  /// 清理空数据
  Future<bool> clearEmpty() async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    // 清理空的会话
    await WKDBHelper.shared.getDB()!.delete(
          WKDBConst.tableConversation,
          where: "last_client_msg_no IS NULL OR last_client_msg_no = ''",
        );
    return true;
  }

  /// 获取会话扩展Map
  Map<String, Object> getExtraMap(WKConversationMsgExtra extra) {
    Map<String, Object> map = <String, Object>{};
    map['channel_id'] = extra.channelID;
    map['channel_type'] = extra.channelType;
    map['browse_to'] = extra.browseTo;
    map['keep_message_seq'] = extra.keepMessageSeq;
    map['keep_offset_y'] = extra.keepOffsetY;
    map['draft'] = extra.draft;
    map['version'] = extra.version;
    map['draft_updated_at'] = extra.draftUpdatedAt;
    return map;
  }
}
