import 'package:sqflite/sqflite.dart';
import '../entity/wk_base_cmd.dart';
import 'wk_db_helper.dart';
import 'const.dart';

/// 2020-11-23 11:48
/// cmd管理
class WKBaseCMDManager {
  WKBaseCMDManager._privateConstructor();
  static final WKBaseCMDManager _instance = WKBaseCMDManager._privateConstructor();
  static WKBaseCMDManager get instance => _instance;

  /// 添加cmd
  Future<void> addCmd(List<WKBaseCMD> list) async {
    if (list.isEmpty) return;
    try {
      List<WKBaseCMD> tempList = [];
      List<Map<String, Object>> cvList = [];
      List<String> clientMsgNos = [];
      List<String> msgIds = [];

      for (WKBaseCMD cmd in list) {
        clientMsgNos.add(cmd.clientMsgNo);
        msgIds.add(cmd.messageID);
      }

      tempList.addAll(await queryWithClientMsgNos(clientMsgNos));
      tempList.addAll(await queryWithMsgIds(msgIds));
      bool isCheck = tempList.isNotEmpty;

      for (WKBaseCMD cmd in list) {
        bool isAdd = true;
        if (isCheck) {
          for (WKBaseCMD existingCmd in tempList) {
            if (existingCmd.clientMsgNo == cmd.clientMsgNo || existingCmd.messageID == cmd.messageID) {
              isAdd = false;
              break;
            }
          }
        }
        if (isAdd) {
          cvList.add(getMap(cmd));
        }
      }

      await WKDBHelper.shared.getDB()!.transaction((txn) async {
        for (Map<String, Object> cv in cvList) {
          txn.insert('cmd', cv, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } catch (e) {
      // 处理异常
    }
  }

  /// 根据client_msg_no查询
  Future<List<WKBaseCMD>> queryWithClientMsgNos(List<String> clientMsgNos) async {
    List<WKBaseCMD> list = [];
    if (WKDBHelper.shared.getDB() == null || clientMsgNos.isEmpty) {
      return list;
    }

    String sql = "SELECT * FROM cmd WHERE client_msg_no IN (${WKDBConst.getPlaceholders(clientMsgNos.length)})";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, clientMsgNos);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(serializeCmd(data));
      }
    }
    return list;
  }

  /// 根据message_id查询
  Future<List<WKBaseCMD>> queryWithMsgIds(List<String> msgIds) async {
    List<WKBaseCMD> list = [];
    if (WKDBHelper.shared.getDB() == null || msgIds.isEmpty) {
      return list;
    }

    String sql = "SELECT * FROM cmd WHERE message_id IN (${WKDBConst.getPlaceholders(msgIds.length)})";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, msgIds);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(serializeCmd(data));
      }
    }
    return list;
  }

  /// 删除cmd
  Future<void> deleteCmd(String clientMsgNo) async {
    if (WKDBHelper.shared.getDB() == null) return;

    Map<String, Object> contentValues = {'is_deleted': 1};
    await WKDBHelper.shared.getDB()!.update('cmd', contentValues, where: 'client_msg_no=?', whereArgs: [clientMsgNo]);
  }

  /// 查询所有cmd
  Future<List<WKBaseCMD>> queryAllCmd() async {
    List<WKBaseCMD> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }

    String sql = "SELECT * FROM cmd WHERE is_deleted=0";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(serializeCmd(data));
      }
    }
    return list;
  }

  /// 获取ContentValues
  Map<String, Object> getMap(WKBaseCMD cmd) {
    return {
      'client_msg_no': cmd.clientMsgNo,
      'cmd': cmd.cmd,
      'sign': cmd.sign,
      'created_at': cmd.createdAt,
      'message_id': cmd.messageID,
      'message_seq': cmd.messageSeq,
      'param': cmd.param,
      'timestamp': cmd.timestamp,
    };
  }

  /// 序列化cmd
  WKBaseCMD serializeCmd(Map<String, Object?> data) {
    WKBaseCMD cmd = WKBaseCMD();
    cmd.clientMsgNo = WKDBConst.readString(data, 'client_msg_no');
    cmd.cmd = WKDBConst.readString(data, 'cmd');
    cmd.createdAt = WKDBConst.readString(data, 'created_at');
    cmd.messageID = WKDBConst.readString(data, 'message_id');
    cmd.messageSeq = WKDBConst.readInt(data, 'message_seq');
    cmd.param = WKDBConst.readString(data, 'param');
    cmd.sign = WKDBConst.readString(data, 'sign');
    cmd.timestamp = WKDBConst.readInt(data, 'timestamp');
    return cmd;
  }

  /// 处理cmd
  Future<void> handleCmd() async {
    List<WKBaseCMD> cmdList = await queryAllCmd();
    if (cmdList.isEmpty) return;

    // 这里可以添加具体的cmd处理逻辑
    // 例如处理撤回消息、RTC等

    // 处理完成后删除cmd
    try {
      await WKDBHelper.shared.getDB()!.transaction((txn) async {
        for (WKBaseCMD cmd in cmdList) {
          await deleteCmd(cmd.clientMsgNo);
        }
      });
    } catch (e) {
      // 处理异常
    }
  }
}
