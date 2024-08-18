class IncomeCategory {
  final int? id;
  final String name;

  IncomeCategory({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory IncomeCategory.fromMap(Map<String, dynamic> map) {
    return IncomeCategory(
      id: map['id'],
      name: map['name'],
    );
  }
}
