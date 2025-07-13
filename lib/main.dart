 import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

 

class TodoModel {
  final String title;
  final String category;
  final DateTime createdAt;
  final DateTime reminderTime;
  bool isCompleted;

  TodoModel({
    required this.title,
    required this.category,
    required this.createdAt,
    required this.reminderTime,
    this.isCompleted = false,
  });
}

 

class TodoHandlerProvider with ChangeNotifier {
  final List<TodoModel> _todos = List.generate(
    5,
    (index) => TodoModel(
      title: 'Task $index',
      category: 'Category ${index % 2}',
      createdAt: DateTime.now().subtract(Duration(days: index)),
      reminderTime: DateTime.now().add(Duration(hours: index + 1)),
    ),
  );

  List<TodoModel> get todos => _todos;

  Future<void> addTask(TodoModel todoModel) async {
    _todos.add(todoModel);
    notifyListeners();
  }

  Future<void> completeTask({required int index}) async {
    if (index >= 0 && index < _todos.length) {
      _todos[index].isCompleted = true;
      notifyListeners();
    }
  }

  Future<void> deleteTask(int index) async {
    if (index >= 0 && index < _todos.length) {
      _todos.removeAt(index);
      notifyListeners();
    }
  }
}

 

class PopupMenuHelper {
  static Widget buildPopupMenu(
    BuildContext context, {
    required void Function(String) onSelected,
    required List<Map<String, String>> optionsList,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: onSelected,
      itemBuilder: (_) => optionsList
          .map((opt) => PopupMenuItem<String>(
                value: opt.keys.first,
                child: Text(opt.values.first),
              ))
          .toList(),
    );
  }
}

 

String formatDateTimeToString(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

String formatTimeFromDateTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

 

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TodoHandlerProvider(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TodoListScreen(),
      ),
    ),
  );
}

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoHandlerProvider>(context);
    final todos = todoProvider.todos;

    return Scaffold(
      appBar: AppBar(title: const Text('Todo List')),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          final isCompleted = todo.isCompleted;

          return Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(),
              color: isCompleted ? Colors.blueAccent.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(1.5, 2),
                  spreadRadius: 1,
                  blurRadius: 4,
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      radius: 8,
                    ),
                    const SizedBox(width: 8),
                    Text(todo.category),
                    const Spacer(),
                    PopupMenuHelper.buildPopupMenu(
                      context,
                      onSelected: (value) async {
                        switch (value) {
                          case "complete":
                            await todoProvider.completeTask(index: index);
                            break;
                          case "delete":
                            await todoProvider.deleteTask(index);
                            break;
                        }
                      },
                      optionsList: [
                        if (!isCompleted) {"complete": "Complete"},
                        {"delete": "Delete"}
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const Icon(Icons.flag, color: Colors.redAccent),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(formatDateTimeToString(todo.createdAt)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timelapse_rounded,
                        color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(formatTimeFromDateTime(todo.reminderTime)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    categoryController.text.isNotEmpty) {
                  final newTask = TodoModel(
                    title: titleController.text,
                    category: categoryController.text,
                    createdAt: DateTime.now(),
                    reminderTime: DateTime.now().add(const Duration(hours: 1)),
                  );

                  Provider.of<TodoHandlerProvider>(context, listen: false)
                      .addTask(newTask);

                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
