class NetWorth {
  final String id;
  final String userId;
  final String dateCalculated;
  final double netWorth;

  NetWorth({
    required this.id,
    required this.userId,
    required this.dateCalculated,
    required this.netWorth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date_calculated': dateCalculated,
      'net_worth': netWorth,
    };
  }

  static NetWorth fromMap(Map<String, dynamic> map) {
    return NetWorth(
      id: map['id'],
      userId: map['user_id'],
      dateCalculated: map['date_calculated'],
      netWorth: map['net_worth'],
    );
  }
}
