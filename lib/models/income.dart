class Income {
  final String id;
  final String userId;
  final String source;
  final double amount;
  final String dateReceived;
  final double taxAmount;

  Income({
    required this.id,
    required this.userId,
    required this.source,
    required this.amount,
    required this.dateReceived,
    required this.taxAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'source': source,
      'amount': amount,
      'date_received': dateReceived,
      'tax_amount': taxAmount,
    };
  }

  static Income fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      userId: map['user_id'],
      source: map['source'],
      amount: map['amount'],
      dateReceived: map['date_received'],
      taxAmount: map['tax_amount'],
    );
  }
}
