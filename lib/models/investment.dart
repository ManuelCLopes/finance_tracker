class Investment {
  final String id;
  final String? investmentType;
  final String? symbol;
  final double initialValue;
  double? currentValue; // Make this non-final if you want to modify it later
  final String dateInvested;

  Investment({
    required this.id,
    this.investmentType,
    this.symbol,
    required this.initialValue,
    this.currentValue,
    required this.dateInvested,
  });

  // Factory constructor to create an instance from a map
  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'] as String,
      investmentType: map['investment_type'] as String?,
      symbol: map['symbol'] as String?,
      initialValue: (map['initial_value'] as num?)?.toDouble() ?? 0.0, // Default to 0.0 if null
      currentValue: (map['current_value'] as num?)?.toDouble(), // Handle null for optional fields
      dateInvested: map['date_invested'] as String,
    );
  }

  // Convert an instance to a map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'investment_type': investmentType,
      'symbol': symbol,
      'initial_value': initialValue,
      'current_value': currentValue,
      'date_invested': dateInvested,
    };
  }
}
