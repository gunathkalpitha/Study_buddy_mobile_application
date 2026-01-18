
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';

class TodoTab extends ConsumerWidget {
  final String groupId;

  const TodoTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(groupTodosProvider(groupId));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context, ref),
        child: const Icon(Icons.add_task),
      ),
      body: todosAsync.when(
        data: (todos) {
          if (todos.isEmpty) {
            return Center(
              child: Text(
                'No tasks yet.\nGet organized!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            );
          }

          final pending = todos.where((t) => !t.completed).toList();
          final completed = todos.where((t) => t.completed).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                Text('Pending', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...pending.map((todo) => _TodoItem(todo: todo, groupId: groupId)),
                const SizedBox(height: 24),
              ],
              if (completed.isNotEmpty) ...[
                Text('Completed', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...completed.map((todo) => _TodoItem(todo: todo, groupId: groupId)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    final taskController = TextEditingController();
    PriorityLevel selectedPriority = PriorityLevel.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(labelText: 'Task Description'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PriorityLevel>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: PriorityLevel.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedPriority = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (taskController.text.isNotEmpty) {
                    final user = ref.read(currentUserProvider);
                    if (user != null) {
                      final newTodo = TodoModel(
                        id: const Uuid().v4(),
                        task: taskController.text,
                        createdBy: user.id,
                        priority: selectedPriority,
                        dueDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      await ref.read(repositoryProvider).addTodo(groupId, newTodo);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TodoItem extends ConsumerWidget {
  final TodoModel todo;
  final String groupId;

  const _TodoItem({required this.todo, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color priorityColor;
    switch (todo.priority) {
      case PriorityLevel.high:
        priorityColor = Colors.red;
        break;
      case PriorityLevel.medium:
        priorityColor = Colors.orange;
        break;
      case PriorityLevel.low:
        priorityColor = Colors.green;
        break;
    }

    return Card(
      elevation: 0,
      color: todo.completed
          ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Checkbox(
          value: todo.completed,
          onChanged: (val) {
            if (val != null) {
              ref.read(repositoryProvider).toggleTodo(groupId, todo.id, val);
            }
          },
        ),
        title: Text(
          todo.task,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? Theme.of(context).colorScheme.outline : null,
          ),
        ),
        subtitle: todo.dueDate != null
            ? Text('Due ${DateFormat('MMM d').format(todo.dueDate!)}')
            : null,
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: priorityColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
