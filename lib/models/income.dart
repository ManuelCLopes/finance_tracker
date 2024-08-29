class Income {
  final String id;
  final String userId;
  final int categoryId; 
  final double amount;
  final double taxAmount;
  final String dateReceived;

  Income({
    required this.id,
    required this.userId,
    required this.categoryId, 
    required this.amount,
    required this.taxAmount,
    required this.dateReceived,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId, 
      'amount': amount,
      'tax_amount': taxAmount,
      'date_received': dateReceived,
    };
  }

  static Income fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      categoryId: map['category_id'] ?? '',
      amount: map['amount'] ?? 0,
      taxAmount: map['tax_amount'] ?? 0.0,
      dateReceived: map['date_received'] ?? '',
    );
  }
}
