import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import 'edit_task_screen.dart';
import 'view_task_screen.dart';

class RoutineTasksScreen extends StatefulWidget {
  final TaskService taskService = TaskService();
  final AuthService authService = AuthService();

  RoutineTasksScreen({super.key});

  @override
  State<RoutineTasksScreen> createState() => _RoutineTasksScreenState();
}

class _RoutineTasksScreenState extends State<RoutineTasksScreen> {
  late Stream<List<Task>> _routineTasksStream;

  @override
  void initState() {
    super.initState();
    final userId = widget.authService.currentUser?.uid;
    if (userId != null) {
      _routineTasksStream = widget.taskService.getRoutineTasks(userId);
    } else {
      _routineTasksStream = Stream.value([]);
    }
  }

  Future<void> _completeTask(Task task) async {
    try {
      await widget.taskService.updateTaskStatus(task.id, TaskStatus.completed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completed "${task.title}"')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete task: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Routines',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _routineTasksStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.repeat, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No routines yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isCompleted = task.status == TaskStatus.completed;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.repeat,
                                  color: isCompleted
                                      ? Colors.grey
                                      : Colors.blue[600],
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isCompleted
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                // Action icons
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Checkmark to complete
                                    if (!isCompleted)
                                      IconButton(
                                        icon: Icon(
                                          Icons.check,
                                          color: Colors.green[600],
                                        ),
                                        onPressed: () => _completeTask(task),
                                        splashRadius: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Complete',
                                      ),
                                    // Eye to view
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_red_eye,
                                        color: Colors.blue[600],
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ViewTaskScreen(task: task),
                                          ),
                                        );
                                      },
                                      splashRadius: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'View',
                                    ),
                                    // Pen to edit
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.orange[600],
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditTaskScreen(task: task),
                                          ),
                                        );
                                      },
                                      splashRadius: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Edit',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (task.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 34, top: 4, bottom: 8),
                                child: Text(
                                  task.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(left: 34),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Due: ${_formatDate(task.dueDate)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (task.routineDays != null &&
                                      task.routineDays!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: task.routineDays!.map((day) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.blue.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            day,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}