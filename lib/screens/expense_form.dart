import 'package:flutter/material.dart';
import '../databases/expense_dao.dart';
import '../models/expense.dart';
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

  late String _selectedCategory;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.expense?.categoryId?.toString() ?? ''; // Adjust based on your category handling
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
          title: Text('Delete Expense'),
          content: Text('Are you sure you want to delete this expense?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteExpense(); // Delete the expense
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
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
        categoryId: int.parse(_selectedCategory), // Adjust based on your category handling
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
        actions: [
          if (widget.expense != null)
            IconButton(
              icon: Icon(Icons.delete),
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
              // Add your category dropdown here
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
                readOnly: true, // Prevents manual input
                onTap: () => _selectDate(context), // Opens date picker on tap
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
