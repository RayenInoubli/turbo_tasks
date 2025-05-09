import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled
}

enum TaskType {
  oneTime,
  routine
}

class Task {
  String id;
  String title;
  String description;
  TaskStatus status;
  TaskType type;
  List<String> tags;
  DateTime dueDate;
  List<String>? routineDays; // null for one-time tasks
  String userId;
  DateTime createdAt;
  DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.type,
    required this.tags,
    required this.dueDate,
    this.routineDays,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a Task from a Firestore document
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: _stringToTaskStatus(data['status'] ?? 'pending'),
      type: data['type'] == 'routine' ? TaskType.routine : TaskType.oneTime,
      tags: List<String>.from(data['tags'] ?? []),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      routineDays: data['type'] == 'routine' ? List<String>.from(data['routineDays'] ?? []) : null,
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert Task to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'status': taskStatusToString(status),
      'type': type == TaskType.routine ? 'routine' : 'oneTime',
      'tags': tags,
      'dueDate': Timestamp.fromDate(dueDate),
      'routineDays': type == TaskType.routine ? routineDays : null,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper method to convert string to TaskStatus enum
  static TaskStatus _stringToTaskStatus(String status) {
    switch (status) {
      case 'pending':
        return TaskStatus.pending;
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  // Helper method to convert TaskStatus enum to string
  static String taskStatusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'inProgress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }

  // Check if task is completed
  bool get isCompleted => status == TaskStatus.completed;

  // Check if task is a routine
  bool get isRoutine => type == TaskType.routine;

  // Create a copy of task with updated fields
  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskType? type,
    List<String>? tags,
    DateTime? dueDate,
    List<String>? routineDays,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? id,
  }) {
    return Task(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      dueDate: dueDate ?? this.dueDate,
      routineDays: routineDays ?? this.routineDays,
      userId: this.userId,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}