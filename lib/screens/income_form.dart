import 'package:flutter/material.dart';
import '../databases/income_dao.dart';
import '../models/income.dart';
import 'package:intl/intl.dart'; // For formatting dates

class IncomeForm extends StatefulWidget {
  final Income? income;

  IncomeForm({this.income});

  @override
  _IncomeFormState createState() => _IncomeFormState();
}

class _IncomeFormState extends State<IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  final IncomeDao _incomeDao = IncomeDao();
  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Investments', 'Other'];

  late String _selectedCategory;
  late TextEditingController _amountController;
  late TextEditingController _taxAmountController;
  late TextEditingController _dateController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.income?.source ?? _incomeCategories.first;
    _amountController = TextEditingController(text: widget.income?.amount.toString() ?? '');
    _taxAmountController = TextEditingController(text: widget.income?.taxAmount.toString() ?? '');
    _selectedDate = widget.income != null ? DateTime.parse(widget.income!.dateReceived) : DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_selectedDate!));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _taxAmountController.dispose();
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

  void _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      final income = Income(
        id: widget.income?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '1', // Replace with actual user ID
        source: _selectedCategory,
        amount: double.tryParse(_amountController.text) ?? 0,
        dateReceived: _formatDate(_selectedDate!),
        taxAmount: double.tryParse(_taxAmountController.text) ?? 0,
      );

      if (widget.income == null) {
        await _incomeDao.insertIncome(income);
      } else {
        await _incomeDao.updateIncome(income);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.income == null ? 'Add Income' : 'Edit Income'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _incomeCategories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Source'),
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _taxAmountController,
                decoration: InputDecoration(labelText: 'Tax Amount'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date Received',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true, // Prevents manual input
                onTap: () => _selectDate(context), // Opens date picker on tap
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveIncome,
                child: Text('Save Income'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
