import 'package:flutter/material.dart';
import '../models/expense_category.dart';
import '../models/income_category.dart';
import '../databases/expense_category_dao.dart';
import '../databases/income_category_dao.dart';

class CategoryManagementScreen extends StatefulWidget {
  @override
  _CategoryManagementScreenState createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final ExpenseCategoryDao _expenseCategoryDao = ExpenseCategoryDao();
  final IncomeCategoryDao _incomeCategoryDao = IncomeCategoryDao();
  List<ExpenseCategory> _expenseCategories = [];
  List<IncomeCategory> _incomeCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    List<ExpenseCategory> expenseCategories = await _expenseCategoryDao.getAllCategories();
    List<IncomeCategory> incomeCategories = await _incomeCategoryDao.getAllCategories();
    setState(() {
      _expenseCategories = expenseCategories;
      _incomeCategories = incomeCategories;
    });
  }

  void _addCategory() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = '';
        bool isExpense = true;

        return AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  name = value;
                },
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              DropdownButtonFormField<bool>(
                value: isExpense,
                items: [
                  const DropdownMenuItem(value: true, child: Text('Expense')),
                  const DropdownMenuItem(value: false, child: Text('Income')),
                ],
                onChanged: (value) {
                  isExpense = value!;
                },
                decoration: const InputDecoration(labelText: 'Category Type'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.isNotEmpty) {
                  if (isExpense) {
                    await _expenseCategoryDao.insertCategory(ExpenseCategory(name: name));
                  } else {
                    await _incomeCategoryDao.insertCategory(IncomeCategory(name: name));
                  }
                  _loadCategories();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editCategory(dynamic category, bool isExpense) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = category.name;

        return AlertDialog(
          title: const Text('Edit Category'),
          content: TextField(
            onChanged: (value) {
              name = value;
            },
            decoration: const InputDecoration(labelText: 'Category Name'),
            controller: TextEditingController(text: category.name),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.isNotEmpty) {
                  if (isExpense) {
                    await _expenseCategoryDao.updateCategory(ExpenseCategory(id: category.id, name: name));
                  } else {
                    await _incomeCategoryDao.updateCategory(IncomeCategory(id: category.id, name: name));
                  }
                  _loadCategories();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(int id, bool isExpense) async {
    if (isExpense) {
      await _expenseCategoryDao.deleteCategory(id);
    } else {
      await _incomeCategoryDao.deleteCategory(id);
    }
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Expense Categories'),
          ),
          ..._expenseCategories.map((category) {
            return ListTile(
              title: Text(category.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editCategory(category, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCategory(category.id!, true),
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(),
          const ListTile(
            title: Text('Income Categories'),
          ),
          ..._incomeCategories.map((category) {
            return ListTile(
              title: Text(category.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editCategory(category, false),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCategory(category.id!, false),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }
}