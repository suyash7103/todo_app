import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:todo_app/models/todo_item.dart';

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List<TodoItem> _todoItems = [];
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final pathToDb = path.join(databasePath, 'todo_database.db');

    _database = await openDatabase(
      pathToDb,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, deadline TEXT, isCompleted INTEGER)',
        );
      },
      version: 1,
    );
    _loadTodoItems();
  }

  Future<void> _loadTodoItems() async {
    final List<Map<String, dynamic>> maps = await _database!.query('todos');
    setState(() {
      _todoItems = List.generate(maps.length, (i) {
        return TodoItem(
          id: maps[i]['id'],
          title: maps[i]['title'],
          deadline: DateTime.parse(maps[i]['deadline']),
          isCompleted: maps[i]['isCompleted'] == 1,
        );
      });
    });
  }

  Future<void> _addTodoItem(TodoItem item) async {
    await _database!.insert(
      'todos',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _loadTodoItems();
  }

  Future<void> _updateTodoItem(TodoItem item) async {
    await _database!.update(
      'todos',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    _loadTodoItems();
  }

  Future<void> _deleteTodoItem(int id) async {
    await _database!.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadTodoItems();
  }

  void _showAddTodoDialog() {
    final _titleController = TextEditingController();
    final _deadlineController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add To-Do Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  fillColor: Colors.grey[300],
                  filled: true,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _deadlineController,
                decoration: InputDecoration(
                  labelText: 'Deadline (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  fillColor: Colors.grey[300],
                  filled: true,
                ),
                keyboardType: TextInputType.datetime,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newItem = TodoItem(
                  title: _titleController.text,
                  deadline: DateTime.parse(_deadlineController.text),
                  isCompleted: false,
                );
                _addTodoItem(newItem);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTodoDialog(TodoItem item) {
    final _titleController = TextEditingController(text: item.title);
    final _deadlineController =
        TextEditingController(text: item.deadline.toIso8601String());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit To-Do Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  fillColor: Colors.grey[300],
                  filled: true,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _deadlineController,
                decoration: InputDecoration(
                  labelText: 'Deadline (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  fillColor: Colors.grey[300],
                  filled: true,
                ),
                keyboardType: TextInputType.datetime,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updatedItem = TodoItem(
                  id: item.id,
                  title: _titleController.text,
                  deadline: DateTime.parse(_deadlineController.text),
                  isCompleted: item.isCompleted,
                );
                _updateTodoItem(updatedItem);
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        backgroundColor: Colors.blue,
      ),
      body: _todoItems.isEmpty
          ? Center(child: Text('No to-do items yet!'))
          : ListView.builder(
              itemCount: _todoItems.length,
              itemBuilder: (BuildContext context, int index) {
                final item = _todoItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.grey[300],
                  elevation: 5,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle:
                        Text('Due: ${item.deadline.toLocal()}'.split(' ')[0]),
                    trailing: Checkbox(
                      activeColor: Colors.blue,
                      checkColor: Colors.white,
                      value: item.isCompleted,
                      onChanged: (bool? value) {
                        final updatedItem = TodoItem(
                          id: item.id,
                          title: item.title,
                          deadline: item.deadline,
                          isCompleted: value!,
                        );
                        _updateTodoItem(updatedItem);
                      },
                    ),
                    onTap: () => _showEditTodoDialog(item),
                    onLongPress: () => _deleteTodoItem(item.id!),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }
}
