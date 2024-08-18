import 'package:flutter/material.dart';
import '../databases/user_dao.dart';
import '../models/user.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final UserDao _userDao = UserDao();
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    // This example assumes that users are stored with some predefined data.
    // Replace with actual data retrieval.
    // _users = await _userDao.getAllUsers(); // Example method you can create
    setState(() {
      _users = [
        User(id: '1', name: 'John Doe', email: 'john@example.com'),
        User(id: '2', name: 'Jane Doe', email: 'jane@example.com'),
      ];
    });
  }

  void _addUser() async {
    User newUser = User(id: '3', name: 'New User', email: 'newuser@example.com');
    await _userDao.insertUser(newUser);
    _loadUsers();
  }

  void _deleteUser(String userId) async {
    await _userDao.deleteUser(userId);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_users[index].name),
            subtitle: Text(_users[index].email ?? 'No Email'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteUser(_users[index].id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        child: Icon(Icons.add),
      ),
    );
  }
}
