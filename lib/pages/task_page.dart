import 'package:flutter/material.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final List<String> _tasks = [];

  final TextEditingController _taskController = TextEditingController();

  void createNewTask() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Task'),
          content: TextField(
            controller: _taskController,
            decoration: const InputDecoration(hintText: 'Enter new task'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks.add(_taskController.text);
                  _taskController.clear();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
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
        title: const Text('Tasks'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        child: const Icon(Icons.add),
      ),
      body: _tasks.isEmpty
          ? const Center(
              child: Text('No tasks yet. Add a new task!'),
            )
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16), // Spacing around the card
                  elevation: 4, // Shadow for the card
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16), // Padding inside the ListTile
                    title: Text(
                      _tasks[index],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red), // Red delete icon
                      onPressed: () {
                        setState(() {
                          _tasks.removeAt(index); // Remove the task
                        });
                      },
                    ),
                    tileColor: Colors.white, // Background color of the ListTile
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          12), // Rounded corners for the ListTile
                    ),
                  ),
                );
              },
            ),
    );
  }
}
