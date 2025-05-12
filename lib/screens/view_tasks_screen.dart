import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_app/screens/edit_task_screen.dart';
import 'package:project_app/screens/view_task_screen.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import 'create_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late TaskService _taskService;
  late String? _userId;
  TaskStatus? _selectedFilter = TaskStatus.inProgress;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _taskService = TaskService();
    _userId = _auth.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Tasks',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFilterChips(),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _selectedFilter == null
                  ? _taskService.getTasks(_userId!) // Show all tasks
                  : _taskService.getTasksByStatus(_userId!, _selectedFilter!), // Filter by status
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
                        const Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tasks yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
                            );
                          },
                          child: const Text('Add a new task'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildDismissibleTaskCard(task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', _selectedFilter == null, () {
            setState(() {
              _selectedFilter = null; // null means show all tasks
            });
          }),
          _buildFilterChip('In Progress', _selectedFilter == TaskStatus.inProgress, () {
            setState(() {
              _selectedFilter = TaskStatus.inProgress;
            });
          }),
          _buildFilterChip('Completed', _selectedFilter == TaskStatus.completed, () {
            setState(() {
              _selectedFilter = TaskStatus.completed;
            });
          }),
          _buildFilterChip('Cancelled', _selectedFilter == TaskStatus.cancelled, () {
            setState(() {
              _selectedFilter = TaskStatus.cancelled;
            });
          }),
          _buildFilterChip('Pending', _selectedFilter == TaskStatus.pending, () {
            setState(() {
              _selectedFilter = TaskStatus.pending;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (value) {
          onTap();
        },
      ),
    );
  }

  Widget _buildDismissibleTaskCard(Task task) {
    return Dismissible(
      key: Key(task.id),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade500,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              'Complete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete, color: Colors.white, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete swipe - show confirmation
          return await _showDeleteConfirmation(task);
        } else {
          // Complete swipe - no confirmation needed
          final previousStatus = task.status;
          if (task.status != TaskStatus.completed) {
            _taskService.updateTaskStatus(task.id, TaskStatus.completed);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task "${task.title}" marked as completed'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    _taskService.updateTaskStatus(task.id, previousStatus);
                  },
                ),
              ),
            );
          }
          return false; // Prevents dismissing the card from view
        }
      },
      child: _buildTaskCard(task),
    );
  }

  Widget _buildTaskCard(Task task) {
    final bool isCompleted = task.status == TaskStatus.completed;
    final bool isCancelled = task.status == TaskStatus.cancelled;

    // Get border and background colors based on status
    final (Color borderColor, Color backgroundColor) = _getCardColors(task.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewTaskScreen(task: task),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: 1),
        ),
        color: backgroundColor,
        child: Stack(
          children: [
            // Task content
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 12, bottom: 16, right: 60),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status indicator
                      Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: borderColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Center(child: _getStatusIcon(task.status)),
                          ),
                          const SizedBox(height: 8), // Added space at the bottom of the icon
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Task details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                decoration: isCompleted || isCancelled ? TextDecoration.lineThrough : null,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: _isPastDue(task.dueDate) && !isCompleted && !isCancelled
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(task.dueDate),
                                  style: TextStyle(
                                    color: _isPastDue(task.dueDate) && !isCompleted && !isCancelled
                                        ? Colors.red
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (task.tags.isNotEmpty)
                              SizedBox(
                                height: 26,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: task.tags.map((tag) => _buildTagChip(tag)).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Slim status indicator at the bottom - same color as card body
                Container(
                  height: 4, // Very small height
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                ),
              ],
            ),

            // Vertical action buttons on the right side
            Positioned(
              top: 8,
              right: 8,
              bottom: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      backgroundColor: Colors.blue.shade100,
                      padding: const EdgeInsets.all(8),
                      visualDensity: VisualDensity.compact,
                      shape: const CircleBorder(),
                    ),
                    tooltip: 'Edit',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTaskScreen(task: task),
                        ),
                      );
                    },
                  ),

                  // Show action buttons based on status
                  if (task.status == TaskStatus.pending || task.status == TaskStatus.inProgress) ...[
                    // Start/Complete button
                    IconButton(
                      icon: Icon(
                        task.status == TaskStatus.pending ? Icons.play_arrow : Icons.check_circle,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: task.status == TaskStatus.pending ? Colors.blue : Colors.green,
                        padding: const EdgeInsets.all(8),
                        visualDensity: VisualDensity.compact,
                        shape: const CircleBorder(),
                      ),
                      tooltip: task.status == TaskStatus.pending ? 'Start' : 'Complete',
                      onPressed: () {
                        _taskService.updateTaskStatus(
                          task.id,
                          task.status == TaskStatus.pending ? TaskStatus.inProgress : TaskStatus.completed,
                        );
                      },
                    ),

                    // Cancel button
                    IconButton(
                      icon: const Icon(Icons.cancel, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(8),
                        visualDensity: VisualDensity.compact,
                        shape: const CircleBorder(),
                      ),
                      tooltip: 'Cancel',
                      onPressed: () {
                        _taskService.updateTaskStatus(task.id, TaskStatus.cancelled);
                      },
                    ),
                  ],

                  // Restore button for completed/cancelled tasks
                  if (task.status == TaskStatus.completed || task.status == TaskStatus.cancelled)
                    IconButton(
                      icon: const Icon(Icons.restore, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: task.status == TaskStatus.completed ? Colors.orange : Colors.blue,
                        padding: const EdgeInsets.all(8),
                        visualDensity: VisualDensity.compact,
                        shape: const CircleBorder(),
                      ),
                      tooltip: task.status == TaskStatus.completed ? 'Mark as Pending' : 'Restore',
                      onPressed: () {
                        _taskService.updateTaskStatus(task.id, TaskStatus.pending);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(Task task) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              _taskService.deleteTask(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Task "${task.title}" deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isPastDue(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  (Color, Color) _getCardColors(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return (Colors.orange, Colors.orange.shade50);
      case TaskStatus.inProgress:
        return (Colors.blue, Colors.blue.shade50);
      case TaskStatus.completed:
        return (Colors.green, Colors.green.shade50);
      case TaskStatus.cancelled:
        return (Colors.red, Colors.red.shade50);
    }
  }

  Icon _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case TaskStatus.inProgress:
        return const Icon(Icons.play_arrow, color: Colors.blue);
      case TaskStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case TaskStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.red);
    }
  }
}