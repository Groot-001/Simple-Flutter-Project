import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart'; // Import LoginPage
import 'password_update_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController(); // Custom category field
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userName = "Guest";
  String? _selectedCategory = "All"; // Default to "All"
  List<String> _categories = [
    'All',
    'Food',
    'Transportation',
    'Entertainment',
    'Bills',
    'Shopping',
    'Other'
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Global key to control the drawer

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  Future<void> _getUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? "Guest";
      });
    }
  }

  Future<void> _addExpense() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please sign in to add an expense')));
      return;
    }

    if (_selectedCategory == null || _selectedCategory == "All") {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please choose a category')));
      return;
    }

    if (_selectedCategory == "Other" &&
        _customCategoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a custom category')));
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter an amount')));
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter a description')));
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    String category = _selectedCategory == "Other"
        ? _customCategoryController.text
        : _selectedCategory!;

    await _firestore.collection('expenses').add({
      'uid': user.uid,
      'category': category,
      'amount': amount,
      'description': _descriptionController.text,
      'date': DateTime.now(),
    });

    _categoryController.clear();
    _amountController.clear();
    _descriptionController.clear();
    _customCategoryController.clear();
  }

  Stream<List<Map<String, dynamic>>> _getExpensesStream() async* {
    final userUid = FirebaseAuth.instance.currentUser?.uid;

    if (userUid == null) {
      yield [];
      return;
    }

    final snapshotStream = _firestore
        .collection('expenses')
        .where('uid', isEqualTo: userUid)
        .snapshots();

    await for (var snapshot in snapshotStream) {
      final expenses = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();

      if (_selectedCategory != null && _selectedCategory != "All") {
        expenses
            .removeWhere((expense) => expense['category'] != _selectedCategory);
      }

      expenses.sort(
          (a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));

      yield expenses;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute}";
  }

  Future<void> _deleteExpense(String expenseId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure?"),
          content: Text(
              "Do you want to delete this expense? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _firestore.collection('expenses').doc(expenseId).delete();
                Navigator.of(context).pop();
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editExpense(String expenseId, String currentCategory,
      double currentAmount, String currentDescription) async {
    _categoryController.text = currentCategory;
    _amountController.text = currentAmount.toString();
    _descriptionController.text = currentDescription;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                double? amount = double.tryParse(_amountController.text);
                if (amount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid amount')));
                  return;
                }

                await _firestore.collection('expenses').doc(expenseId).update({
                  'category': _categoryController.text,
                  'amount': amount,
                  'description': _descriptionController.text,
                });

                _categoryController.clear();
                _amountController.clear();
                _descriptionController.clear();
                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Attach the scaffold key to control the drawer
      appBar: AppBar(
        title: Text('Hello, $_userName!'),
        leading: IconButton(
          icon: Icon(Icons.menu), // Hamburger icon
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer
          },
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Welcome, $_userName!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Update Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PasswordUpdatePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              hint: Text("Select Category"),
              value: _selectedCategory,
              onChanged: (String? newCategory) {
                setState(() {
                  _selectedCategory = newCategory;
                });
              },
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ),
          ),
          if (_selectedCategory == "Other")
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _customCategoryController,
                decoration: InputDecoration(labelText: 'Enter Custom Category'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.blue, // Correct parameter to set the button color
              ),
              onPressed: _addExpense,
              child: Text("Add Expense"),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getExpensesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No expenses to display.'));
                }

                var expenses = snapshot.data!;

                return ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    var expense = expenses[index];
                    Color categoryColor;

                    switch (expense['category']) {
                      case 'Food':
                        categoryColor = Colors.green;
                        break;
                      case 'Transportation':
                        categoryColor = Colors.blue;
                        break;
                      case 'Entertainment':
                        categoryColor = Colors.orange;
                        break;
                      case 'Bills':
                        categoryColor = Colors.red;
                        break;
                      default:
                        categoryColor = Colors.grey;
                    }

                    return Card(
                      margin: EdgeInsets.all(8),
                      elevation: 5,
                      child: ListTile(
                        leading: Icon(
                          Icons.category,
                          color: categoryColor,
                        ),
                        title: Text(expense['category']),
                        subtitle: Text(
                            "${expense['description']} - ${expense['amount']} - ${_formatDate(expense['date'])}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _editExpense(
                                  expense['id'],
                                  expense['category'],
                                  expense['amount'],
                                  expense['description'],
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () {
                                _deleteExpense(expense['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
