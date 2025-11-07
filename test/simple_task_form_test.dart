import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/task.dart';

// Simplified form for testing
class SimpleTaskForm extends StatefulWidget {
  final VoidCallback onSaved;
  final Task? task;

  const SimpleTaskForm({super.key, required this.onSaved, this.task});

  @override
  State<SimpleTaskForm> createState() => _SimpleTaskFormState();
}

class _SimpleTaskFormState extends State<SimpleTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSaved();
              }
            },
            child: const Text('CREATE TASK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

void main() {
  testWidgets('SimpleTaskForm validates and saves', (tester) async {
    bool savedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SimpleTaskForm(
            onSaved: () {
              savedCalled = true;
            },
          ),
        ),
      ),
    );

    // Initial build
    await tester.pump();

    // No title - validation should fail
    await tester.tap(find.text('CREATE TASK'));
    await tester.pump();
    expect(savedCalled, isFalse);
    expect(find.text('Please enter a title'), findsOneWidget);

    // Enter title
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Test Task',
    );
    await tester.pump();

    // Submit should work
    await tester.tap(find.text('CREATE TASK'));
    await tester.pump();
    expect(savedCalled, isTrue);
  });
}
