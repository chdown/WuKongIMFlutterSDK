/// 2020-11-23 11:50
/// cmd
class WKBaseCMD {
  String messageID = '';
  int messageSeq = 0;
  String clientMsgNo = '';
  int timestamp = 0;
  String cmd = '';
  String sign = '';
  String param = '';
  int isDeleted = 0;
  String createdAt = '';

  WKBaseCMD();

  WKBaseCMD.fromMap(Map<String, dynamic> map) {
    messageID = map['message_id'] ?? '';
    messageSeq = map['message_seq'] ?? 0;
    clientMsgNo = map['client_msg_no'] ?? '';
    timestamp = map['timestamp'] ?? 0;
    cmd = map['cmd'] ?? '';
    sign = map['sign'] ?? '';
    param = map['param'] ?? '';
    isDeleted = map['is_deleted'] ?? 0;
    createdAt = map['created_at'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageID,
      'message_seq': messageSeq,
      'client_msg_no': clientMsgNo,
      'timestamp': timestamp,
      'cmd': cmd,
      'sign': sign,
      'param': param,
      'is_deleted': isDeleted,
      'created_at': createdAt,
    };
  }
}
