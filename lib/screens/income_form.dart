import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../databases/income_category_dao.dart';
import '../databases/income_dao.dart';
import '../models/income.dart';
import '../models/income_category.dart';

class IncomeForm extends StatefulWidget {
  final Income? income;

  IncomeForm({super.key, this.income});

  @override
  _IncomeFormState createState() => _IncomeFormState();
}

class _IncomeFormState extends State<IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  final IncomeDao _incomeDao = IncomeDao();
  final IncomeCategoryDao _incomeCategoryDao = IncomeCategoryDao();

  late String _selectedCategory;
  late TextEditingController _amountController;
  late TextEditingController _taxAmountController;
  late TextEditingController _dateController;
  DateTime? _selectedDate;
  List<IncomeCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.income?.categoryId.toString() ?? '';
    _amountController = TextEditingController(text: widget.income?.amount.toString() ?? '');
    _taxAmountController = TextEditingController(text: widget.income?.taxAmount.toString() ?? '');
    _selectedDate = widget.income != null ? DateTime.parse(widget.income!.dateReceived) : DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_selectedDate!));

    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _taxAmountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    List<IncomeCategory> categories = await _incomeCategoryDao.getAllCategories();
    setState(() {
      _categories = categories;
      if (_selectedCategory.isEmpty && _categories.isNotEmpty) {
        _selectedCategory = _categories.first.id!.toString();
      }
    });
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

  Future<void> _deleteIncome() async {
    if (widget.income != null) {
      await _incomeDao.deleteIncome(widget.income!.id);
      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Income'),
          content: const Text('Are you sure you want to delete this income?'),
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
                _deleteIncome(); 
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      final income = Income(
        id: widget.income?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '1', // Replace with actual user ID
        amount: double.tryParse(_amountController.text) ?? 0,
        dateReceived: _formatDate(_selectedDate!),
        categoryId: int.parse(_selectedCategory),
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
        actions: [
          if (widget.income != null)
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
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id.toString(),
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxAmountController,
                decoration: const InputDecoration(labelText: 'Tax Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the tax amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date Received',
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
                onPressed: _saveIncome,
                child: const Text('Save Income'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
