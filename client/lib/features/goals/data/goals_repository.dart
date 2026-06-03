import '../../../core/api/api_client.dart';
import '../../../core/constants/constants.dart';
import '../domain/models.dart';
import '../../tasks/domain/models.dart';

class GoalDetailData {
  final Goal goal;
  final List<dynamic> tasks;

  GoalDetailData({required this.goal, required this.tasks});
}

class GoalsRepository {
  final ApiClient _apiClient;

  GoalsRepository(this._apiClient);

  Future<List<Goal>> getGoals() async {
    final response = await _apiClient.get(ApiConstants.goals);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      final list = data['data'] as List;
      return list.map((e) => Goal.fromJson(e)).toList();
    }
    throw ApiException(message: data['message'] ?? '获取目标失败');
  }

  Future<Goal> getGoal(int id) async {
    final response = await _apiClient.get('${ApiConstants.goals}/$id');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Goal.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '获取目标失败');
  }

  Future<GoalDetailData> getGoalDetail(int id) async {
    final response = await _apiClient.get('${ApiConstants.goals}/$id');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      // Backend returns goal directly at data['data'], not data['data']['goal']
      final goalData = data['data'] as Map<String, dynamic>;
      return GoalDetailData(
        goal: Goal.fromJson(goalData),
        tasks: const [],
      );
    }
    throw ApiException(message: data['message'] ?? '获取目标详情失败');
  }

  Future<List<Task>> getTasksByGoalId(int goalId) async {
    final response = await _apiClient.get(
      ApiConstants.tasks,
      queryParameters: {'goalId': goalId},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      final list = data['data'] as List;
      return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException(message: data['message'] ?? '获取任务列表失败');
  }

  Future<List<Map<String, dynamic>>> getNotesByGoalId(int goalId) async {
    final response = await _apiClient.get('${ApiConstants.studyLogs}/goal/$goalId');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      final logs = data['data'] as List;
      return logs.cast<Map<String, dynamic>>();
    }
    throw ApiException(message: data['message'] ?? '获取笔记列表失败');
  }

  Future<Goal> createGoal({
    required String title,
    String? description,
    required GoalType type,
    required Priority priority,
    DateTime? deadline,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.goals,
      data: {
        'title': title,
        'description': description,
        'type': type.name,
        'priority': priority.name,
        'deadline': deadline?.toIso8601String(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Goal.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '创建目标失败');
  }

  Future<Goal> updateGoal(int id, Map<String, dynamic> updates) async {
    final response = await _apiClient.put(
      '${ApiConstants.goals}/$id',
      data: updates,
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Goal.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '更新目标失败');
  }

  Future<void> deleteGoal(int id) async {
    final response = await _apiClient.delete('${ApiConstants.goals}/$id');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] != 200) {
      throw ApiException(message: data['message'] ?? '删除目标失败');
    }
  }
}