import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int todayTasks;
  final int todayReviews;
  final int completedToday;
  final int todayStudyDuration;
  final int consecutiveDays;
  final int totalGoals;
  final int totalTasks;
  final int completedTasks;
  final double completionRate;

  const DashboardStats({
    required this.todayTasks,
    required this.todayReviews,
    required this.completedToday,
    required this.todayStudyDuration,
    required this.consecutiveDays,
    required this.totalGoals,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todayTasks: json['todayTasks'] as int? ?? 0,
      todayReviews: json['todayReviews'] as int? ?? 0,
      completedToday: json['completedToday'] as int? ?? 0,
      todayStudyDuration: json['todayStudyDuration'] as int? ?? 0,
      consecutiveDays: json['consecutiveDays'] as int? ?? 0,
      totalGoals: json['totalGoals'] as int? ?? 0,
      totalTasks: json['totalTasks'] as int? ?? 0,
      completedTasks: json['completedTasks'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [todayTasks, todayReviews, completedToday];
}