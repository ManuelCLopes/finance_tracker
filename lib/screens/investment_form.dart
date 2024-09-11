import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../databases/investment_dao.dart';
import '../models/investment.dart';
import '../services/app_localizations_service.dart';
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
  late TextEditingController _quantityController; // Controller for Quantity
  String _selectedDuration = '-';
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
    _quantityController = TextEditingController(text: widget.investment?.quantity.toString() ?? '0'); // Initialize Quantity Controller
    _selectedDuration = widget.investment?.duration ?? _durations.first;
    _selectedDate = widget.investment != null ? DateTime.parse(widget.investment!.dateInvested) : DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_selectedDate!));
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
    _quantityController.dispose(); // Dispose Quantity Controller
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
            if (cryptoDetails['current_price']?.toDouble() != null) {
              final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0.0;
              _currentValue = quantity * cryptoDetails['current_price'].toDouble();
              _quantityController.text = quantity.toStringAsFixed(5);
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
          }
        );
      } else {
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

  void _saveInvestment() async {
    if (_formKey.currentState!.validate()) {
      final initialValue = double.tryParse(_initialValueController.text.replaceAll(',', '.')) ?? 0;
      final annualReturn = double.tryParse(_annualReturnController.text.replaceAll(',', '.'));
      final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0.0;
      final roundedQuantity = double.parse(quantity.toStringAsFixed(5));
    
      final investment = Investment(
        id: widget.investment?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: _symbolController.text,
        investmentType: _selectedType,
        initialValue: initialValue,
        currentValue: _currentValue,
        dateInvested: _formatDate(_selectedDate!),
        investmentProduct: _selectedType == 'Cryptocurrency' ? _stockName : (_selectedType == 'Constant Return' || _selectedType == 'Other' ? _investmentProductController.text : _stockName),
        quantity: roundedQuantity,
        annualReturn: annualReturn,
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
        title: Text(
          widget.investment == null
              ? AppLocalizations.of(context)!.translate('add_investment')
              : AppLocalizations.of(context)!.translate('edit_investment')
        ),
        actions: [
          if (widget.investment != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await _investmentDao.deleteInvestment(widget.investment!.id);
                Navigator.pop(context);
              },
              tooltip: AppLocalizations.of(context)?.translate('delete'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('date_invested'),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
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
                      _currentValue = null;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('investment_type'),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedType == 'Stocks' || _selectedType == 'ETFs' || _selectedType == 'Cryptocurrency') ...[
                  TextFormField(
                    controller: _symbolController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.translate('symbol') ?? 'Symbol',
                    ),
                    onChanged: (value) {
                      _fetchFinancialData();
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
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _initialValueController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.translate('initial_value'),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[,|.]?\d*')),
                  ],
                  onChanged: (value) {
                    _updateQuantityBasedOnInitialValue();
                  },
                  validator: (value) {
                    final sanitizedValue = value?.replaceAll(',', '.');
                    final number = double.tryParse(sanitizedValue!);
                    if (number == null) {
                      return AppLocalizations.of(context)?.translate('enter_initial_value');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedType == 'Stocks' || _selectedType == 'ETFs' || _selectedType == 'Cryptocurrency')
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.translate('quantity'),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[,|.]?\d*')),
                    ],
                    onChanged: (value) {
                      _updateInitialValueBasedOnQuantity();
                    },
                  ),
                if (_currentValue != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '${AppLocalizations.of(context)?.translate('current_value')}: ${_currentValue?.toStringAsFixed(2)} $_currencySymbol',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveInvestment,
                  child: Text(AppLocalizations.of(context)!.translate('save_investment')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateQuantityBasedOnInitialValue() async {
    final initialValue = double.tryParse(_initialValueController.text.replaceAll(",", ".")) ?? 0.0;
    if (initialValue > 0 && _symbolController.text.isNotEmpty) {
      if (_selectedType == 'Stocks' || _selectedType == 'ETFs') {
        final stockPrice = await FinnhubService.getRealTimeData(_symbolController.text);
        if (stockPrice != null) {
          setState(() {
            final quantity = initialValue / stockPrice;
            _quantityController.text = quantity.toString();
          });
        }
      } else if (_selectedType == 'Cryptocurrency') {
        final cryptoDetails = await CryptoService().getCryptoDetails(_symbolController.text);
        if (cryptoDetails != null) {
          final cryptoPrice = cryptoDetails['current_price']?.toDouble() ?? 1.0;
          setState(() {
            final quantity = initialValue / cryptoPrice;
            _quantityController.text = quantity.toString(); 
          });
        }
      }
    }
  }

  void _updateInitialValueBasedOnQuantity() async {
    final quantity = double.tryParse(_quantityController.text.replaceAll(",", ".")) ?? 0.0;
    if (quantity > 0 && _symbolController.text.isNotEmpty) {
      if (_selectedType == 'Stocks' || _selectedType == 'ETFs') {
        final stockPrice = await FinnhubService.getRealTimeData(_symbolController.text);
        if (stockPrice != null) {
          setState(() {
            final initialValue = quantity * stockPrice;
            _initialValueController.text = initialValue.toStringAsFixed(2);
          });
        }
      } else if (_selectedType == 'Cryptocurrency') {
        final cryptoDetails = await CryptoService().getCryptoDetails(_symbolController.text);
        if (cryptoDetails != null) {
          final cryptoPrice = cryptoDetails['current_price']?.toDouble() ?? 1.0;
          setState(() {
            final initialValue = quantity * cryptoPrice;
            _initialValueController.text = initialValue.toStringAsFixed(2);
          });
        }
      }
    }
  }
  
}
