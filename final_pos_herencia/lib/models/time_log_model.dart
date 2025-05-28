class TimeLogModel {
  int? id;
  String? firebaseDocId;
  String cashierId;
  int loginTime;
  int? logoutTime;
  bool isSynced;

  TimeLogModel({
    this.id,
    this.firebaseDocId,
    required this.cashierId,
    required this.loginTime,
    this.logoutTime,
    this.isSynced = false,
  });

  TimeLogModel copyWith({
    int? id,
    String? firebaseDocId,
    String? cashierId,
    int? loginTime,
    int? logoutTime,
    bool? isSynced,
  }) {
    return TimeLogModel(
      id: id ?? this.id,
      firebaseDocId: firebaseDocId ?? this.firebaseDocId,
      cashierId: cashierId ?? this.cashierId,
      loginTime: loginTime ?? this.loginTime,
      logoutTime: logoutTime ?? this.logoutTime,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebase_doc_id': firebaseDocId,
      'cashier_id': cashierId,
      'login_time': loginTime,
      'logout_time': logoutTime,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory TimeLogModel.fromMap(Map<String, dynamic> map) {
    return TimeLogModel(
      id: map['id'],
      firebaseDocId: map['firebase_doc_id'],
      cashierId: map['cashier_id'],
      loginTime: map['login_time'],
      logoutTime: map['logout_time'],
      isSynced: map['is_synced'] == 1,
    );
  }
} 