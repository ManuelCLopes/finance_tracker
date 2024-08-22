class Investment {
  final String id;
  final String? symbol;
  final String? investmentType;
  final double initialValue;
  double? currentValue;
  final String dateInvested;
  final String? investmentProduct;
  double? quantity;
  double? annualReturn;
  String? duration;

  Investment({
    required this.id,
    this.symbol,
    this.investmentType,
    required this.initialValue,
    this.currentValue,
    required this.dateInvested,
    this.investmentProduct,
    required this.quantity, 
    this.annualReturn, 
    this.duration,
  });

  Investment copyWith({
    String? id,
    String? symbol,
    String? investmentType,
    double? initialValue,
    double? currentValue,
    String? dateInvested,
    String? investmentProduct,
    double? quantity,
    double? annualReturn,
    String? duration,
  }) {
    return Investment(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      investmentType: investmentType ?? this.investmentType,
      initialValue: initialValue ?? this.initialValue,
      currentValue: currentValue ?? this.currentValue,
      dateInvested: dateInvested ?? this.dateInvested,
      investmentProduct: investmentProduct ?? this.investmentProduct,
      quantity: quantity ?? this.quantity,
      annualReturn: annualReturn ?? this.annualReturn,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol': symbol,
      'investment_type': investmentType,
      'initial_value': initialValue,
      'current_value': currentValue,
      'date_invested': dateInvested,
      'investment_product': investmentProduct,
      'quantity': quantity,
      'annual_return': annualReturn,
      'duration': duration
    };
  }

  static Investment fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      symbol: map['symbol'],
      investmentType: map['investment_type'],
      initialValue: map['initial_value'],
      currentValue: map['current_value'],
      dateInvested: map['date_invested'],
      investmentProduct: map['investment_product'],
      quantity: map['quantity'],
      annualReturn: map['annual_return'],
      duration: map['duration']
    );
  }
}
