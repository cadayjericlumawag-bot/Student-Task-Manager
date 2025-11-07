import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../sql_helper/database_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Task? task;
  final List<Map<String, dynamic>>? testUsers;
  final Map<String, dynamic>? currentUser;

  const TaskFormSheet({
    super.key,
    required this.onSaved,
    this.task,
    this.testUsers,
    this.currentUser,
  });

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scrollController = ScrollController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TaskPriority _selectedPriority;
  int? _selectedAssigneeId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now.add(const Duration(days: 1));
    _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    _selectedPriority = TaskPriority.medium;

    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.dueDate;
      _selectedTime = TimeOfDay(
        hour: widget.task!.dueDate.hour,
        minute: widget.task!.dueDate.minute,
      );
      _selectedPriority = widget.task!.priority;
      _selectedAssigneeId = widget.task!.assigneeId;
    }

    if (widget.currentUser != null) {
      _selectedAssigneeId = widget.currentUser!['id'];
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('TaskFormSheet: Form validation failed');
      return;
    }

    final currentUserId = widget.currentUser?['id'] as int?;
    if (currentUserId == null) {
      debugPrint('TaskFormSheet: No current user found');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not determine current user'),
        ),
      );
      return;
    }
    _selectedAssigneeId = currentUserId;

    try {
      setState(() => _isLoading = true);

      final dueDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: dueDateTime,
        priority: _selectedPriority,
        assigneeId: _selectedAssigneeId!,
        createdById: widget.currentUser != null
            ? (widget.currentUser!['id'] as int)
            : _selectedAssigneeId!,
        ownerUid:
            FirebaseAuth.instance.currentUser?.uid ??
            (widget.currentUser != null
                ? 'local:${widget.currentUser!['id']}'
                : null),
        status: TaskStatus.todo,
      );

      if (widget.task == null) {
        await DatabaseHelper.createTask(task.toMap());
      } else {
        await DatabaseHelper.updateTask(widget.task!.id!, task.toMap());
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onSaved();
    } catch (e) {
      debugPrint('TaskFormSheet: Error saving task: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving task: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          minHeight: 200,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.task == null ? 'Create Task' : 'Edit Task',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null && mounted) {
                                  setState(() {
                                    _selectedDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      _selectedTime.hour,
                                      _selectedTime.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                'Due: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedTime,
                                );
                                if (picked != null && mounted) {
                                  setState(() {
                                    _selectedTime = picked;
                                    _selectedDate = DateTime(
                                      _selectedDate.year,
                                      _selectedDate.month,
                                      _selectedDate.day,
                                      picked.hour,
                                      picked.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                'Time: ${_selectedTime.format(context)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TaskPriority>(
                        initialValue: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: TaskPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPriority = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Assignee',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                        ),
                        initialValue: widget.currentUser != null
                            ? widget.currentUser!['fullName'] as String
                            : FirebaseAuth.instance.currentUser?.displayName ??
                                  FirebaseAuth.instance.currentUser?.email ??
                                  'Current User',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveTask,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.task == null
                                      ? 'CREATE TASK'
                                      : 'UPDATE TASK',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
