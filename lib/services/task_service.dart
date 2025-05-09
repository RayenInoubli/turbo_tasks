import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // Get a reference to the tasks collection
  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection(_collection);

  // Create a new task
  Future<Task> createTask(Task newTask) async {
    final docRef = await _tasksCollection.add(newTask.toFirestore());

    return newTask.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Get all tasks for a user
  Stream<List<Task>> getTasks(String userId) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Get tasks by type (one-time or routine)
  Stream<List<Task>> getTasksByType(String userId, TaskType type) {
    final typeString = type == TaskType.routine ? 'routine' : 'oneTime';
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: typeString)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Get tasks by status
  Stream<List<Task>> getTasksByStatus(String userId, TaskStatus status) {
    String statusString = Task.taskStatusToString(status);
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: statusString)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Get tasks with specific tag
  Stream<List<Task>> getTasksByTag(String userId, String tag) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('tags', arrayContains: tag)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Update a task
  Future<void> updateTask(Task task) {
    return _tasksCollection.doc(task.id).update({
      'title': task.title,
      'description': task.description,
      'status': Task.taskStatusToString(task.status),
      'type': task.type == TaskType.routine ? 'routine' : 'oneTime',
      'tags': task.tags,
      'dueDate': Timestamp.fromDate(task.dueDate),
      'routineDays': task.type == TaskType.routine ? task.routineDays : null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) {
    return _tasksCollection.doc(taskId).update({
      'status': Task.taskStatusToString(status),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete a task
  Future<void> deleteTask(String taskId) {
    return _tasksCollection.doc(taskId).delete();
  }

  // Get a single task by ID
  Future<Task?> getTask(String taskId) async {
    final doc = await _tasksCollection.doc(taskId).get();
    if (doc.exists) {
      return Task.fromFirestore(doc);
    }
    return null;
  }

  // Get tasks due today for a user
  Stream<List<Task>> getTasksDueToday(String userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Get all tags for a user
  Future<List<String>> getUserTags(String userId) async {
    final tasks = await _tasksCollection
        .where('userId', isEqualTo: userId)
        .get();

    Set<String> tags = {};
    for (var doc in tasks.docs) {
      List<String> taskTags = List<String>.from(doc.data()['tags'] ?? []);
      tags.addAll(taskTags);
    }

    return tags.toList();
  }

  // Add to your TaskService class
  Stream<List<Task>> getRoutineTasks(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'routine')
        .where('status', whereIn: ['pending', 'inProgress']) // Not completed
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }
}