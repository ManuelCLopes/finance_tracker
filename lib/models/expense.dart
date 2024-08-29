class Expense {
  final String id;
  final String userId;
  final int categoryId;
  final double amount;
  final String dateSpent;

  Expense({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.dateSpent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'date_spent': dateSpent,
    };
  }

  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      categoryId: map['category_id'] ?? '',
      amount: map['amount'] ?? 0.0,
      dateSpent: map['date_spent'] ?? '',
    );
  }
}
