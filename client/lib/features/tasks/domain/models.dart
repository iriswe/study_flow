import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Task extends Equatable {
  final int id;
  final int goalId;
  final String goalTitle;
  final String title;
  final TaskStatus status;
  final String priority;
  final int? estimateMinutes;
  final int? actualMinutes;
  final DateTime? dueDate;
  final int sortOrder;
  final String? note;
  final TaskType taskType;
  final String? recurringFrequency;
  final TimeOfDay? recurringTime;
  final int currentStreak;
  final int longestStreak;
  final int totalCompleted;
  final bool checkedInToday;
  final List<SubTask> subTasks;
  final bool hasReview;
  final int? progressPercent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Task({
    required this.id,
    required this.goalId,
    required this.goalTitle,
    required this.title,
    required this.status,
    required this.priority,
    this.estimateMinutes,
    this.actualMinutes,
    this.dueDate,
    required this.sortOrder,
    this.note,
    this.taskType = TaskType.PROGRESSION,
    this.recurringFrequency,
    this.recurringTime,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompleted = 0,
    this.checkedInToday = false,
    this.subTasks = const [],
    this.hasReview = false,
    this.progressPercent,
    required this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      goalId: json['goalId'] as int,
      goalTitle: json['goalTitle'] as String? ?? '',
      title: json['title'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.PENDING,
      ),
      priority: json['priority'] as String,
      estimateMinutes: json['estimateMinutes'] as int?,
      actualMinutes: json['actualMinutes'] as int?,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      sortOrder: json['sortOrder'] as int? ?? 0,
      note: json['note'] as String?,
      taskType: TaskType.values.firstWhere(
        (e) => e.name == json['taskType'],
        orElse: () => TaskType.PROGRESSION,
      ),
      recurringFrequency: json['recurringFrequency'] as String?,
      recurringTime: json['recurringTime'] != null
          ? _parseTimeOfDay(json['recurringTime'] as String)
          : null,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalCompleted: json['totalCompleted'] as int? ?? 0,
      checkedInToday: json['checkedInToday'] as bool? ?? false,
      subTasks: (json['subTasks'] as List?)
              ?.map((e) => SubTask.fromJson(e))
              .toList() ??
          [],
      hasReview: json['hasReview'] as bool? ?? false,
      progressPercent: json['progressPercent'] as int?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  bool get isDone => taskType == TaskType.HABIT ? checkedInToday : status == TaskStatus.COMPLETED;

  bool get isDueToday {
    if (taskType != TaskType.HABIT) return true;
    final now = DateTime.now();
    switch (recurringFrequency) {
      case 'DAILY':
        return true;
      case 'WEEKDAYS':
        return now.weekday >= 1 && now.weekday <= 5;
      case 'WEEKLY':
        return now.weekday == createdAt.weekday;
      default:
        return true;
    }
  }

  @override
  List<Object?> get props => [id, title, status, priority, checkedInToday];
}

enum TaskType {
  PROGRESSION,  // 进度任务
  HABIT         // 习惯任务
}

extension TaskTypeExtension on TaskType {
  String get label {
    switch (this) {
      case TaskType.PROGRESSION:
        return '进度任务';
      case TaskType.HABIT:
        return '习惯任务';
    }
  }
}

enum RecurringFrequency {
  DAILY,    // 每天
  WEEKLY,   // 每周
  WEEKDAYS  // 工作日
}

extension RecurringFrequencyExtension on RecurringFrequency {
  String get label {
    switch (this) {
      case RecurringFrequency.DAILY:
        return '每天';
      case RecurringFrequency.WEEKLY:
        return '每周';
      case RecurringFrequency.WEEKDAYS:
        return '工作日';
    }
  }
}

enum TaskStatus {
  PENDING,    // 待办
  IN_PROGRESS, // 进行中
  COMPLETED   // 已完成
}

extension TaskStatusExtension on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.PENDING:
        return '待办';
      case TaskStatus.IN_PROGRESS:
        return '进行中';
      case TaskStatus.COMPLETED:
        return '已完成';
    }
  }
}

class SubTask extends Equatable {
  final int id;
  final String title;
  final bool completed;
  final int sortOrder;

  const SubTask({
    required this.id,
    required this.title,
    required this.completed,
    required this.sortOrder,
  });

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, title, completed];
}

TimeOfDay _parseTimeOfDay(String timeStr) {
  final parts = timeStr.split(':');
  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );
}