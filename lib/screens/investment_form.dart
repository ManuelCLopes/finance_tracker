import 'package:flutter/material.dart';
import '../databases/investment_dao.dart';
import '../models/investment.dart';
import 'package:intl/intl.dart';

class InvestmentForm extends StatefulWidget {
  final Investment? investment;

  InvestmentForm({super.key, this.investment});

  @override
  _InvestmentFormState createState() => _InvestmentFormState();
}

class _InvestmentFormState extends State<InvestmentForm> {
  final _formKey = GlobalKey<FormState>();
  final InvestmentDao _investmentDao = InvestmentDao();
  final List<String> _investmentTypes = ['Stocks', 'Bonds', 'Real Estate', 'Mutual Funds', 'Other'];

  late String _selectedType;
  late TextEditingController _symbolController;
  late TextEditingController _initialValueController;
  late TextEditingController _currentValueController;
  late TextEditingController _dateController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.investment?.investmentType ?? _investmentTypes.first;
    _symbolController = TextEditingController(text: widget.investment?.symbol ?? '');
    _initialValueController = TextEditingController(text: widget.investment?.initialValue.toString() ?? '');
    _currentValueController = TextEditingController(text: widget.investment?.currentValue.toString() ?? '');
    _selectedDate = widget.investment != null ? DateTime.parse(widget.investment!.dateInvested) : DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_selectedDate!));
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _initialValueController.dispose();
    _currentValueController.dispose();
    _dateController.dispose();
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

  Future<void> _deleteInvestment() async {
    if (widget.investment != null) {
      await _investmentDao.deleteInvestment(widget.investment!.id);
      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Investment'),
          content: const Text('Are you sure you want to delete this investment?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteInvestment();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _saveInvestment() async {
    if (_formKey.currentState!.validate()) {
      final investment = Investment(
        id: widget.investment?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        investmentType: _selectedType,
        symbol: _symbolController.text.trim(), // Add the symbol
        initialValue: double.tryParse(_initialValueController.text) ?? 0,
        currentValue: double.tryParse(_currentValueController.text) ?? 0,
        dateInvested: _formatDate(_selectedDate!),
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
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                  });
                },
                decoration: const InputDecoration(labelText: 'Investment Type'),
              ),
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(labelText: 'Investment Symbol'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the investment symbol';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _initialValueController,
                decoration: const InputDecoration(labelText: 'Initial Value'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an initial value';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _currentValueController,
                decoration: const InputDecoration(labelText: 'Current Value'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a current value';
                  }
                  return null;
                },
              ),
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
