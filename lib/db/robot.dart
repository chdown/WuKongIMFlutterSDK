import 'package:sqflite/sqflite.dart';
import 'package:wukongimfluttersdk/db/const.dart';
import 'package:wukongimfluttersdk/entity/robot.dart';
import 'package:wukongimfluttersdk/entity/robot_menu.dart';

import 'wk_db_helper.dart';

class RobotDB {
  RobotDB._privateConstructor();
  static final RobotDB _instance = RobotDB._privateConstructor();
  static RobotDB get shared => _instance;

  // 插入或更新机器人
  Future<void> insertOrUpdateRobots(List<WKRobot> list) async {
    if (WKDBHelper.shared.getDB() == null || list.isEmpty) {
      return;
    }
    for (WKRobot robot in list) {
      await WKDBHelper.shared.getDB()!.insert(WKDBConst.tableRobot, getMap(robot), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // 查询机器人
  Future<WKRobot?> query(String robotID) async {
    WKRobot? robot;
    if (WKDBHelper.shared.getDB() == null) {
      return robot;
    }
    List<Map<String, Object?>> list = await WKDBHelper.shared.getDB()!.query(WKDBConst.tableRobot, where: "robot_id=?", whereArgs: [robotID]);
    if (list.isNotEmpty) {
      robot = WKDBConst.serializeRobot(list[0]);
    }
    return robot;
  }

  // 查询所有机器人
  Future<List<WKRobot>> queryAll() async {
    List<WKRobot> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.query(WKDBConst.tableRobot, orderBy: "created_at DESC");
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeRobot(data));
      }
    }
    return list;
  }

  // 删除机器人
  Future<bool> deleteWithRobotID(String robotID) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    int row = await WKDBHelper.shared.getDB()!.delete(WKDBConst.tableRobot, where: "robot_id=?", whereArgs: [robotID]);
    return row > 0;
  }

  // 清空所有机器人
  Future<void> clearAll() async {
    if (WKDBHelper.shared.getDB() == null) {
      return;
    }
    await WKDBHelper.shared.getDB()!.delete(WKDBConst.tableRobot);
  }

  dynamic getMap(WKRobot robot) {
    var map = <String, Object>{};
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
}

class RobotMenuDB {
  RobotMenuDB._privateConstructor();
  static final RobotMenuDB _instance = RobotMenuDB._privateConstructor();
  static RobotMenuDB get shared => _instance;

  // 插入或更新机器人菜单
  Future<void> insertOrUpdateMenus(List<WKRobotMenu> list) async {
    if (WKDBHelper.shared.getDB() == null || list.isEmpty) {
      return;
    }
    for (WKRobotMenu menu in list) {
      await WKDBHelper.shared.getDB()!.insert(WKDBConst.tableRobotMenu, getMap(menu), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // 查询机器人菜单
  Future<List<WKRobotMenu>> queryRobotMenus(String robotID) async {
    List<WKRobotMenu> list = [];
    if (WKDBHelper.shared.getDB() == null) {
      return list;
    }
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.query(
      WKDBConst.tableRobotMenu,
      where: "robot_id=?",
      whereArgs: [robotID],
      orderBy: "sort ASC",
    );
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(WKDBConst.serializeRobotMenu(data));
      }
    }
    return list;
  }

  // 检查菜单是否存在
  Future<bool> isExitMenu(String robotID, String cmd) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.query(
      WKDBConst.tableRobotMenu,
      where: "robot_id=? and cmd=?",
      whereArgs: [robotID, cmd],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  // 删除机器人菜单
  Future<bool> deleteWithRobotID(String robotID) async {
    if (WKDBHelper.shared.getDB() == null) {
      return false;
    }
    int row = await WKDBHelper.shared.getDB()!.delete(WKDBConst.tableRobotMenu, where: "robot_id=?", whereArgs: [robotID]);
    return row > 0;
  }

  // 清空所有机器人菜单
  Future<void> clearAll() async {
    if (WKDBHelper.shared.getDB() == null) {
      return;
    }
    await WKDBHelper.shared.getDB()!.delete(WKDBConst.tableRobotMenu);
  }

  dynamic getMap(WKRobotMenu menu) {
    var map = <String, Object>{};
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
