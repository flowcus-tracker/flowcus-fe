// task_provider.dart
import 'package:flutter/material.dart';

class TaskProvider extends ChangeNotifier {
  final List<String> _tasks = [];

  List<String> get tasks => _tasks;

  addTask(String task) {
    if (tasks.isEmpty) return Placeholder(child: Text('No task added yet'));
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(int index) {
    _tasks.removeAt(index);
    notifyListeners();
  }
}
