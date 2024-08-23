import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../databases/investment_dao.dart';
import '../models/investment.dart';
import '../utils/currency_utils.dart';
import '../services/finnhub_service.dart';
import '../services/crypto_service.dart';
import '../services/IndexSearchService.dart';

class InvestmentForm extends StatefulWidget {
  final Investment? investment;

  InvestmentForm({super.key, this.investment});

  @override
  _InvestmentFormState createState() => _InvestmentFormState();
}

class _InvestmentFormState extends State<InvestmentForm> {
  final _formKey = GlobalKey<FormState>();
  final InvestmentDao _investmentDao = InvestmentDao();
  final List<String> _investmentTypes = [
    'Stocks',
    'ETFs',
    'Cryptocurrency',
    'Constant Return',
    'Other'
  ];
  final List<String> _durations = ['-', '3 months', '6 months', '12 months'];

  late String _selectedType;
  late TextEditingController _initialValueController;
  late TextEditingController _symbolController;
  late TextEditingController _dateController;
  late TextEditingController _annualReturnController;
  late TextEditingController _investmentProductController;
  String _selectedDuration = '-';
  late double _stockQuantity;
  late String _stockName;
  DateTime? _selectedDate;
  double? _currentValue;
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.investment?.investmentType ?? _investmentTypes.first;
    _symbolController = TextEditingController(text: widget.investment?.symbol ?? '');
    _initialValueController = TextEditingController(text: widget.investment?.initialValue.toString() ?? '');
    _annualReturnController = TextEditingController(text: widget.investment?.annualReturn?.toString() ?? '');
    _investmentProductController = TextEditingController(text: widget.investment?.investmentProduct ?? '');
    _selectedDuration = widget.investment?.duration ?? _durations.first;
    _selectedDate = widget.investment != null ? DateTime.parse(widget.investment!.dateInvested) : DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_selectedDate!));
    _stockQuantity = widget.investment?.quantity ?? 0.0;
    _stockName = widget.investment?.investmentProduct ?? '';
    _currentValue = widget.investment?.currentValue;

    _loadCurrencySymbol();
  }

  Future<void> _loadCurrencySymbol() async {
    _currencySymbol = await CurrencyUtils.getCurrencySymbol();
    setState(() {});
  }

  @override
  void dispose() {
    _initialValueController.dispose();
    _symbolController.dispose();
    _annualReturnController.dispose();
    _dateController.dispose();
    _investmentProductController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate!,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _fetchFinancialData() async {
    String input = _symbolController.text.trim().toUpperCase();

    try {
      if (_selectedType == 'Cryptocurrency') {
        final cryptoDetails = await CryptoService().getCryptoDetails(input);
        if (cryptoDetails != null) {
          setState(() {
            _stockName = cryptoDetails['name'] ?? 'Cryptocurrency Not Found';
            _currentValue = cryptoDetails['current_price']?.toDouble();
            if (_currentValue != null) {
              final initialValue = double.tryParse(_initialValueController.text) ?? 0.0;
              _stockQuantity = initialValue / _currentValue!;
            }
          });
        } else {
          setState(() {
            _stockName = _stockName;
          });
        }
      } else if (_selectedType == 'ETFs') {
        IndexSearchService.searchIndex(
          input,
          context,
          (symbol, name) async {
              setState(() {
                _symbolController.text = symbol;
                _stockName = name;
              });
            });
          }
          else {
            final stockName = await FinnhubService.getStockName(input);
            setState(() {
              _stockName = stockName ?? 'Product Not Found';
            });
          }
    } catch (e) {
      setState(() {
        _stockName = 'Error fetching data';
      });
    }
  }

  Future<void> _calculateStockQuantity() async {
    final initialValue = double.tryParse(_initialValueController.text) ?? 0.0;
    if (initialValue > 0 && _symbolController.text.isNotEmpty) {
      if (_selectedType == 'Stocks' || _selectedType == 'ETFs') {
        final stockPrice = await FinnhubService.getHistoricalData(
          _symbolController.text,
          _dateController.text,
        );
        if (stockPrice != null) {
          setState(() {
            _stockQuantity = initialValue / stockPrice;
            _currentValue = _stockQuantity * stockPrice;
          });
        }
      } else if (_selectedType == 'Cryptocurrency') {
        await _fetchFinancialData(); // Fetch crypto data if the selected type is Cryptocurrency
      }
    }
  }

  void _saveInvestment() async {
    if (_formKey.currentState!.validate()) {
      final investment = Investment(
        id: widget.investment?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: _symbolController.text,
        investmentType: _selectedType,
        initialValue: double.tryParse(_initialValueController.text) ?? 0,
        currentValue: _currentValue,
        dateInvested: _formatDate(_selectedDate!),
        investmentProduct: _selectedType == 'Cryptocurrency' ? _stockName : (_selectedType == 'Constant Return' ? _investmentProductController.text : _stockName),
        quantity: _stockQuantity,
        annualReturn: double.tryParse(_annualReturnController.text),
        duration: _selectedDuration,
      );

      if (widget.investment == null) {
        await _investmentDao.insertInvestment(investment);
      } else {
        await _investmentDao.updateInvestment(investment);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.investment == null ? 'Add Investment' : 'Edit Investment'),
        actions: [
          if (widget.investment != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await _investmentDao.deleteInvestment(widget.investment!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date Invested',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),  // Add spacing between form fields
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _investmentTypes.map((String type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _stockName = '';
                    _stockQuantity = 0.0;
                    _currentValue = null;
                  });
                },
                decoration: const InputDecoration(labelText: 'Investment Type'),
              ),
              const SizedBox(height: 16),  // Add spacing between form fields
              if (_selectedType == 'Stocks' || _selectedType == 'ETFs' || _selectedType == 'Cryptocurrency') ...[
                TextFormField(
                  controller: _symbolController,
                  decoration: const InputDecoration(labelText: 'Symbol'),
                  onChanged: (value) {
                    _fetchFinancialData(); // Fetch data for both stock/ETF and cryptocurrency
                  },
                ),
                if (_stockName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _stockName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                const SizedBox(height: 16),  // Add spacing between form fields
              ],
              if (_selectedType == 'Constant Return') ...[
                TextFormField(
                  controller: _investmentProductController,
                  decoration: const InputDecoration(
                    labelText: 'Investment Product',
                    hintText: 'e.g., Trade Republic',
                  ),
                ),
                const SizedBox(height: 16),  // Add spacing between form fields
                TextFormField(
                  controller: _annualReturnController,
                  decoration: const InputDecoration(labelText: 'Annual Return (%)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),  // Add spacing between form fields
                DropdownButtonFormField<String>(
                  value: _selectedDuration,
                  items: _durations.map((String duration) {
                    return DropdownMenuItem(
                      value: duration,
                      child: Text(duration),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDuration = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: 'Select duration',
                  ),
                ),
                const SizedBox(height: 16),  // Add spacing between form fields
              ],
              TextFormField(
                controller: _initialValueController,
                decoration: const InputDecoration(labelText: 'Initial Value'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _calculateStockQuantity(); // Fetch and calculate stock or crypto quantity
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an initial value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),  // Add spacing between form fields
              if (_selectedType == 'Stocks' || _selectedType == 'ETFs' || _selectedType == 'Cryptocurrency')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '${_selectedType == 'Cryptocurrency' ? 'Crypto' : 'Stock/ETF'} Quantity: ${_stockQuantity.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (_currentValue != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Current Value: ${_currentValue?.toStringAsFixed(2)} $_currencySymbol',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveInvestment,
                child: const Text('Save Investment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
