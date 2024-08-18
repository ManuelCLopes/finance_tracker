class Investment {
  final String id;
  final String userId;
  final String investmentType;
  final double initialValue;
  final double currentValue;
  final String dateInvested;

  Investment({
    required this.id,
    required this.userId,
    required this.investmentType,
    required this.initialValue,
    required this.currentValue,
    required this.dateInvested,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'investment_type': investmentType,
      'initial_value': initialValue,
      'current_value': currentValue,
      'date_invested': dateInvested,
    };
  }

  static Investment fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      userId: map['user_id'],
      investmentType: map['investment_type'],
      initialValue: map['initial_value'],
      currentValue: map['current_value'],
      dateInvested: map['date_invested'],
    );
  }
}
