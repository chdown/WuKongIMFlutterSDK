import '../entity/prohibit_word.dart';
import 'wk_db_helper.dart';
import 'const.dart';

/// 敏感词管理
class ProhibitWordDB {
  ProhibitWordDB._privateConstructor();
  static final ProhibitWordDB _instance = ProhibitWordDB._privateConstructor();
  static ProhibitWordDB get instance => _instance;

  static const String table = 'prohibit_words';

  /// 保存敏感词列表
  Future<void> save(List<ProhibitWord> list) async {
    if (list.isEmpty) return;

    List<int> ids = [];
    for (ProhibitWord word in list) {
      ids.add(word.id);
    }

    List<ProhibitWord> updateList = await queryWithIds(ids);
    List<Map<String, Object>> insertCVList = [];
    List<Map<String, Object>> updateCVList = [];

    for (ProhibitWord word in list) {
      bool isAdd = true;
      if (updateList.isNotEmpty) {
        for (ProhibitWord updateWord in updateList) {
          if (updateWord.id == word.id) {
            updateCVList.add(getCV(word));
            isAdd = false;
            break;
          }
        }
      }
      if (isAdd) {
        insertCVList.add(getCV(word));
      }
    }

    try {
      await WKDBHelper.shared.getDB()!.transaction((txn) async {
        if (insertCVList.isNotEmpty) {
          for (Map<String, Object> cv in insertCVList) {
            await txn.insert(table, cv);
          }
        }
        if (updateCVList.isNotEmpty) {
          for (Map<String, Object> cv in updateCVList) {
            int sid = cv['sid'] as int;
            await txn.update(table, cv, where: 'sid=?', whereArgs: [sid.toString()]);
          }
        }
      });
    } catch (e) {
      // 处理异常
    }
  }

  /// 获取最大版本号
  Future<int> getMaxVersion() async {
    if (WKDBHelper.shared.getDB() == null) {
      return 0;
    }

    String sql = "SELECT * FROM $table ORDER BY version DESC LIMIT 1";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (results.isNotEmpty) {
      ProhibitWord word = serialize(results.first);
      return word.version;
    }
    return 0;
  }

  /// 获取所有敏感词
  Future<List<ProhibitWord>> getAll() async {
    List<ProhibitWord> result = [];
    if (WKDBHelper.shared.getDB() == null) {
      return result;
    }

    String sql = "SELECT * FROM $table WHERE is_deleted=0";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        result.add(serialize(data));
      }
    }
    return result;
  }

  /// 根据ID列表查询
  Future<List<ProhibitWord>> queryWithIds(List<int> list) async {
    List<ProhibitWord> result = [];
    if (WKDBHelper.shared.getDB() == null || list.isEmpty) {
      return result;
    }

    String sql = "SELECT * FROM $table WHERE sid IN (${WKDBConst.getPlaceholders(list.length)})";
    List<Map<String, Object?>> results = await WKDBHelper.shared.getDB()!.rawQuery(sql, list);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        result.add(serialize(data));
      }
    }
    return result;
  }

  /// 获取ContentValues
  Map<String, Object> getCV(ProhibitWord word) {
    return {
      'content': word.content,
      'is_deleted': word.isDeleted,
      'sid': word.id,
      'version': word.version,
      'created_at': word.createdAt,
    };
  }

  /// 序列化敏感词
  ProhibitWord serialize(Map<String, Object?> data) {
    ProhibitWord word = ProhibitWord();
    word.content = WKDBConst.readString(data, 'content');
    word.version = WKDBConst.readInt(data, 'version');
    word.isDeleted = WKDBConst.readInt(data, 'is_deleted');
    word.id = WKDBConst.readInt(data, 'sid');
    word.createdAt = WKDBConst.readString(data, 'created_at');
    return word;
  }
}
