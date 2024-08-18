class Expense {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final String dateSpent;

  Expense({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.dateSpent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'amount': amount,
      'date_spent': dateSpent,
    };
  }

  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      userId: map['user_id'],
      category: map['category'],
      amount: map['amount'],
      dateSpent: map['date_spent'],
    );
  }
}
