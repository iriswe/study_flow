import 'package:equatable/equatable.dart';

class Goal extends Equatable {
  final int id;
  final String title;
  final String? description;
  final GoalType type;
  final Priority priority;
  final DateTime? deadline;
  final double progress;
  final int totalTasks;
  final int completedTasks;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.priority,
    this.deadline,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.createdAt,
    this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: GoalType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GoalType.OTHER,
      ),
      priority: Priority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => Priority.P2,
      ),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      totalTasks: json['totalTasks'] as int? ?? 0,
      completedTasks: json['completedTasks'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  @override
  List<Object?> get props => [id, title, type, priority, progress];
}

enum GoalType {
  PROGRAMMING,  // 编程学习
  CERTIFICATION, // 考证备考
  SKILL,        // 技能训练
  OTHER         // 其他
}

enum Priority {
  P0,  // 紧急
  P1,  // 重要
  P2   // 普通
}

extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.P0:
        return '紧急';
      case Priority.P1:
        return '重要';
      case Priority.P2:
        return '普通';
    }
  }
}

extension GoalTypeExtension on GoalType {
  String get label {
    switch (this) {
      case GoalType.PROGRAMMING:
        return '编程学习';
      case GoalType.CERTIFICATION:
        return '考证备考';
      case GoalType.SKILL:
        return '技能训练';
      case GoalType.OTHER:
        return '其他';
    }
  }
}