import 'package:flutter/material.dart';
import '../models/todo.dart';
import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

class TodoHome extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const TodoHome({super.key, required this.onThemeChanged});
  @override
  State<TodoHome> createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> {
  final List<Todo> _todos = [];
  final TextEditingController _controller = TextEditingController();
  bool _isDarkMode = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
    widget.onThemeChanged(_isDarkMode);
  }

  Future<void> _saveTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      _todos.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('todos', encodedData);
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('todos');

    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        _todos.clear();
        _todos.addAll(decoded.map((e) => Todo.fromJson(e)));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _loadTheme();
  }

  void _addTodo() {
    if (_controller.text.isEmpty) return;

    final newTodo = Todo(title: _controller.text);

    setState(() {
      _todos.add(newTodo);
      _listKey.currentState?.insertItem(_todos.length - 1);
      _controller.clear();
    });

    _saveTodos();
  }

  void _removeAnimated(int index) {
    final removedItem = _todos[index];

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _buildRemovedItem(removedItem),
      ),
      duration: const Duration(milliseconds: 300),
    );

    setState(() {
      _todos.removeAt(index);
    });

    _saveTodos();
  }

  Widget _buildRemovedItem(Todo todo) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(title: Text(todo.title)),
    );
  }

  void _editTodo(int index) {
    TextEditingController editController = TextEditingController(
      text: _todos[index].title,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: 'Update task'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (editController.text.isEmpty) return;

                setState(() {
                  _todos[index].title = editController.text;
                });

                _saveTodos();

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodoItem(int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Checkbox(
            key: ValueKey(_todos[index].isCompleted),
            value: _todos[index].isCompleted,
            onChanged: (value) {
              setState(() {
                _todos[index].isCompleted = value!;
              });
              _saveTodos();
            },
          ),
        ),
        title: Text(
          _todos[index].title,
          style: TextStyle(
            decoration: _todos[index].isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editTodo(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeAnimated(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do List'),
        centerTitle: true,
        actions: [
          Switch(
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              widget.onThemeChanged(value);
              _saveTheme(value);
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter task',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _addTodo,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _todos.length,
              itemBuilder: (context, index, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: _buildTodoItem(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
