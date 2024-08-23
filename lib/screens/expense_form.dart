import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../databases/expense_category_dao.dart';
import '../databases/expense_dao.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/app_localizations_service.dart'; // Import the localization service

class ExpenseForm extends StatefulWidget {
  final Expense? expense;

  const ExpenseForm({super.key, this.expense});

  @override
  _ExpenseFormState createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final ExpenseDao _expenseDao = ExpenseDao();
  final ExpenseCategoryDao _expenseCategoryDao = ExpenseCategoryDao();

  late String _selectedCategory;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  DateTime? _selectedDate;
  List<ExpenseCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.expense?.categoryId.toString() ?? '';
    _amountController = TextEditingController(text: widget.expense?.amount.toString() ?? '');
    _selectedDate = widget.expense != null ? DateTime.parse(widget.expense!.dateSpent) : DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_selectedDate!));

    _loadCategories();
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

  Future<void> _deleteExpense() async {
    if (widget.expense != null) {
      await _expenseDao.deleteExpense(widget.expense!.id);
      Navigator.pop(context); // Close the form after deletion
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.translate('delete_expense') ?? 'Delete Expense'),
          content: Text(AppLocalizations.of(context)?.translate('delete_expense_confirmation') ?? 'Are you sure you want to delete this expense?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteExpense(); // Delete the expense
              },
              child: Text(
                AppLocalizations.of(context)?.translate('delete') ?? 'Delete',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '1', // Replace with actual user ID
        amount: double.tryParse(_amountController.text) ?? 0,
        dateSpent: _formatDate(_selectedDate!),
        categoryId: int.parse(_selectedCategory),
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
        title: Text(widget.expense == null
            ? AppLocalizations.of(context)?.translate('add_expense') ?? 'Add Expense'
            : AppLocalizations.of(context)?.translate('edit_expense') ?? 'Edit Expense'),
        actions: [
          if (widget.expense != null)
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
            crossAxisAlignment: CrossAxisAlignment.start, // Align left for better readability
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.translate('category') ?? 'Category',
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                ),
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
                    return AppLocalizations.of(context)?.translate('please_select_category') ?? 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16), // Space between fields
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.translate('amount') ?? 'Amount',
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)?.translate('please_enter_amount') ?? 'Please enter an amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.translate('date_spent') ?? 'Date Spent',
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 24), // Additional space before the button
              Center( // Center the button
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  child: Text(AppLocalizations.of(context)?.translate('save_expense') ?? 'Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
