class Savings {
  final String id;
  final String userId;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final String dateGoalSet;

  Savings({
    required this.id,
    required this.userId,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    required this.dateGoalSet,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'goal_name': goalName,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'date_goal_set': dateGoalSet,
    };
  }

  static Savings fromMap(Map<String, dynamic> map) {
    return Savings(
      id: map['id'],
      userId: map['user_id'],
      goalName: map['goal_name'],
      targetAmount: map['target_amount'],
      currentAmount: map['current_amount'],
      dateGoalSet: map['date_goal_set'],
    );
  }
}
