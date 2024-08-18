import 'package:flutter/material.dart';
import '../databases/expense_category_dao.dart';
import '../databases/expense_dao.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import 'package:intl/intl.dart';

class ExpenseForm extends StatefulWidget {
  final Expense? expense;

  ExpenseForm({this.expense});

  @override
  _ExpenseFormState createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final ExpenseDao _expenseDao = ExpenseDao();
  final ExpenseCategoryDao _expenseCategoryDao = ExpenseCategoryDao();

  List<ExpenseCategory> _categories = [];
  ExpenseCategory? _selectedCategory;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Load categories when the form is initialized
    _amountController = TextEditingController(text: widget.expense?.amount.toString() ?? '');
    _selectedDate = widget.expense != null ? DateTime.parse(widget.expense!.dateSpent) : DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_selectedDate!));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    List<ExpenseCategory> categories = await _expenseCategoryDao.getAllCategories();
    setState(() {
      _categories = categories;
      _selectedCategory = widget.expense != null
          ? _categories.firstWhere((category) => category.id == widget.expense!.categoryId)
          : _categories.isNotEmpty ? _categories.first : null;
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

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '1', // Replace with actual user ID
        categoryId: _selectedCategory!.id!, // Use the selected category's ID
        amount: double.tryParse(_amountController.text) ?? 0,
        dateSpent: _formatDate(_selectedDate!),
      );

      if (widget.expense == null) {
        await _expenseDao.insertExpense(expense);
      } else {
        await _expenseDao.updateExpense(expense);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<ExpenseCategory>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (ExpenseCategory? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                decoration: InputDecoration(labelText: 'Category'),
                validator: (value) => value == null ? 'Please select a category' : null,
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
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date Spent',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveExpense,
                child: Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
