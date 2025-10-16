import 'package:sqflite/sqflite.dart';
import 'package:wukongimfluttersdk/db/const.dart';
import 'package:wukongimfluttersdk/entity/robot.dart';
import 'package:wukongimfluttersdk/entity/robot_menu.dart';

import 'wk_db_helper.dart';

class RobotDB {
  RobotDB._privateConstructor();
  static final RobotDB _instance = RobotDB._privateConstructor();
  static RobotDB get shared => _instance;

  // ========== 机器人相关方法 ==========

  /// 插入或更新机器人
  Future<bool> insertOrUpdateRobots(List<WKRobot> list) async {
    if (WKDBHelper.shared.getDB() == null || list.isEmpty) {
      return false;
    }
    List<Map<String, Object>> cvList = [];
    for (WKRobot robot in list) {
      cvList.add(getRobotMap(robot));
    }
    await WKDBHelper.shared.getDB()!.transaction((txn) async {
      for (int i = 0; i < cvList.length; i++) {
        txn.insert(WKDBConst.tableRobot, cvList[i], conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return true;
  }

  /// 插入机器人
  Future<bool> insertRobots(List<WKRobot> list) async {
    if (WKDBHelper.shared.getDB() == null || list.isEmpty) {
      return false;
    }
    List<Map<String, Object>> cvList = [];
    for (WKRobot robot in list) {
      cvList.add(getRobotMap(robot));
    }
    await WKDBHelper.shared.getDB()!.transaction((txn) async {
      for (int i = 0; i < cvList.length; i++) {
        txn.insert(WKDBConst.tableRobot, cvList[i], conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return true;
  }

  /// 查询机器人
  Future<WKRobot?> query(String robotID) async {
    if (WKDBHelper.shared.getDB() == null) {
      return null;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableRobot} WHERE robot_id=?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [robotID]);
    if (results.isNotEmpty) {
      return WKDBConst.serializeWKRobot(results.first);
    }
    return null;
  }

  /// 按用户名查询机器人
  Future<WKRobot?> queryWithUsername(String username) async {
    if (WKDBHelper.shared.getDB() == null) {
      return null;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableRobot} WHERE robot_name=?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [username]);
    if (results.isNotEmpty) {
      return WKDBConst.serializeWKRobot(results.first);
    }
    return null;
  }

  /// 查询机器人列表
  Future<List<WKRobot>> queryRobots(List<String> robotIds) async {
    List<WKRobot> list = [];
    if (WKDBHelper.shared.getDB() == null || robotIds.isEmpty) {
      return list;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableRobot} WHERE robot_id IN (${WKDBConst.getPlaceholders(robotIds.length)})";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, robotIds);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKRobot(data));
      }
    }
    return list;
  }

  // ========== 机器人菜单相关方法 ==========

  /// 插入或更新机器人菜单
  Future<bool> insertOrUpdateMenus(List<WKRobotMenu> list) async {
    if (WKDBHelper.shared.getDB() == null || list.isEmpty) {
      return false;
    }
    List<Map<String, Object>> cvList = [];
    for (WKRobotMenu menu in list) {
      cvList.add(getRobotMenuMap(menu));
    }
    await WKDBHelper.shared.getDB()!.transaction((txn) async {
      for (int i = 0; i < cvList.length; i++) {
        txn.insert(WKDBConst.tableRobotMenu, cvList[i], conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return true;
  }

  /// 插入机器人菜单
  Future<bool> insertMenus(List<WKRobotMenu> list) async {
    if (WKDBHelper.shared.getDB() == null || list.isEmpty) {
      return false;
    }
    List<Map<String, Object>> cvList = [];
    for (WKRobotMenu menu in list) {
      cvList.add(getRobotMenuMap(menu));
    }
    await WKDBHelper.shared.getDB()!.transaction((txn) async {
      for (int i = 0; i < cvList.length; i++) {
        txn.insert(WKDBConst.tableRobotMenu, cvList[i], conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return true;
  }

  /// 查询机器人菜单(按多个robotID)
  Future<List<WKRobotMenu>> queryRobotMenus(List<String> robotIds) async {
    List<WKRobotMenu> list = [];
    if (WKDBHelper.shared.getDB() == null || robotIds.isEmpty) {
      return list;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableRobotMenu} WHERE robot_id IN (${WKDBConst.getPlaceholders(robotIds.length)}) ORDER BY sort ASC";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, robotIds);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKRobotMenu(data));
      }
    }
    return list;
  }

  /// 查询机器人菜单(按单个robotID)
  Future<List<WKRobotMenu>> queryRobotMenusByID(String robotID) async {
    List<WKRobotMenu> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    String sql = "SELECT * FROM ${WKDBConst.tableRobotMenu} WHERE robot_id=? ORDER BY sort ASC";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [robotID]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeWKRobotMenu(data));
      }
    }
    return list;
  }

  /// 检查菜单是否存在
  Future<bool> isExitMenu(String robotID, String cmd) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    String sql = "SELECT COUNT(*) as count FROM ${WKDBConst.tableRobotMenu} WHERE robot_id=? AND cmd=?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [robotID, cmd]);
    if (results.isNotEmpty) {
      return WKDBConst.readInt(results.first, 'count') > 0;
    }
    return false;
  }

  // ========== 补充缺失的方法 ==========

  /// 检查机器人是否存在
  Future<bool> isExist(String robotID) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    String sql = "SELECT COUNT(*) as count FROM ${WKDBConst.tableRobot} WHERE robot_id=?";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, [robotID]);
    if (results.isNotEmpty) {
      return WKDBConst.readInt(results.first, 'count') > 0;
    }
    return false;
  }

  // ========== 辅助方法 ==========

  /// 获取机器人Map
  Map<String, Object> getRobotMap(WKRobot robot) {
    Map<String, Object> map = <String, Object>{};
    map['robot_id'] = robot.robotID;
    map['robot_name'] = robot.robotName;
    map['robot_avatar'] = robot.robotAvatar;
    map['robot_type'] = robot.robotType;
    map['status'] = robot.status;
    map['version'] = robot.version;
    map['created_at'] = robot.createdAt;
    map['updated_at'] = robot.updatedAt;
    map['extra'] = robot.extra?.toString() ?? "";
    return map;
  }

  /// 获取机器人菜单Map
  Map<String, Object> getRobotMenuMap(WKRobotMenu menu) {
    Map<String, Object> map = <String, Object>{};
    map['robot_id'] = menu.robotID;
    map['cmd'] = menu.cmd;
    map['name'] = menu.name;
    map['icon'] = menu.icon;
    map['type'] = menu.type;
    map['sort'] = menu.sort;
    map['status'] = menu.status;
    map['version'] = menu.version;
    map['created_at'] = menu.createdAt;
    map['updated_at'] = menu.updatedAt;
    map['extra'] = menu.extra?.toString() ?? "";
    return map;
  }
}
