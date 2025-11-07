import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

export 'package:myapp/widgets/task_form_sheet.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'package:myapp/models/task.dart';
import 'package:myapp/widgets/task_form_sheet.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  Timer? _clockTimer;
  StreamSubscription? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final ownerUid = user?.uid;

      final tasks = await DatabaseHelper.getTasks(ownerUid: ownerUid);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tasks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showTaskFormSheet({Task? task}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          TaskFormSheet(task: task, onSaved: () => _loadTasks()),
    );
    _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.deleteTask(task.id!);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.title}" deleted'),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
        ),
      );

      _loadTasks();
    }
  }

  Future<void> _handleTaskStatusChange(Task task, bool? value) async {
    if (task.status == TaskStatus.completed) {
      return; // Don't allow changes if already completed
    }

    if (!value!) {
      // Unchecking - always allowed
      await DatabaseHelper.updateTaskStatus(task.id!, TaskStatus.todo);
      _loadTasks();
      return;
    }

    // Check if task is overdue
    final now = DateTime.now();
    if (task.dueDate.isBefore(now)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot complete "${task.title}" - task is overdue',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Update task status to overdue
      await DatabaseHelper.updateTaskStatus(task.id!, TaskStatus.overdue);
      _loadTasks();
      return;
    }

    // Not overdue - mark as completed
    await DatabaseHelper.updateTaskStatus(task.id!, TaskStatus.completed);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Task "${task.title}" completed!',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () async {
            await DatabaseHelper.updateTaskStatus(task.id!, TaskStatus.todo);
            _loadTasks();
          },
        ),
      ),
    );

    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = Task.fromMap(_tasks[index]);
                return ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.status == TaskStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.status == TaskStatus.overdue
                          ? Colors.red
                          : null,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      task.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: task.status == TaskStatus.completed,
                        onChanged: task.status == TaskStatus.overdue
                            ? null // Disable checkbox for overdue tasks
                            : (bool? value) {
                                _handleTaskStatusChange(task, value);
                              },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red[400],
                        onPressed: () => _deleteTask(task),
                      ),
                    ],
                  ),
                  onTap: () => _showTaskFormSheet(task: task),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTaskFormSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
