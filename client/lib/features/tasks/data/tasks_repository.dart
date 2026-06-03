import '../../../core/api/api_client.dart';
import '../../../core/constants/constants.dart';
import '../domain/models.dart';

class TasksRepository {
  final ApiClient _apiClient;

  TasksRepository(this._apiClient);

  Future<List<Task>> getTasks({bool todayOnly = false}) async {
    final uri = todayOnly ? '${ApiConstants.tasks}?todayOnly=true' : ApiConstants.tasks;
    final response = await _apiClient.get(uri);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      final list = data['data'] as List;
      return list.map((e) => Task.fromJson(e)).toList();
    }
    throw ApiException(message: data['message'] ?? '获取任务失败');
  }

  Future<List<Task>> getTasksByGoalId(int goalId) async {
    final response = await _apiClient.get(ApiConstants.tasks, queryParameters: {'goalId': goalId});
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      final list = data['data'] as List;
      return list.map((e) => Task.fromJson(e)).toList();
    }
    throw ApiException(message: data['message'] ?? '获取任务失败');
  }

  Future<Task> getTask(int id) async {
    final response = await _apiClient.get('${ApiConstants.tasks}/$id');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Task.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '获取任务失败');
  }

  Future<Task> createTask({
    required int goalId,
    required String title,
    required String priority,
    int? estimateMinutes,
    DateTime? dueDate,
    String? note,
    TaskType taskType = TaskType.PROGRESSION,
    String? recurringFrequency,
    String? recurringTime,
    List<String>? subTasks,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.tasks,
      data: {
        'goalId': goalId,
        'title': title,
        'priority': priority,
        'estimateMinutes': estimateMinutes,
        'dueDate': dueDate?.toIso8601String(),
        'note': note,
        'taskType': taskType.name,
        'recurringFrequency': recurringFrequency,
        'recurringTime': recurringTime,
        'subTasks': subTasks,
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Task.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '创建任务失败');
  }

  Future<Task> updateTask({
    required int id,
    required int goalId,
    required String title,
    required String priority,
    required TaskStatus status,
    int? estimateMinutes,
    DateTime? dueDate,
    String? note,
    TaskType? taskType,
    String? recurringFrequency,
    String? recurringTime,
    List<String>? subTasks,
  }) async {
    final statusStr = switch (status) {
      TaskStatus.PENDING => 'PENDING',
      TaskStatus.IN_PROGRESS => 'IN_PROGRESS',
      TaskStatus.COMPLETED => 'COMPLETED',
    };
    final response = await _apiClient.put(
      '${ApiConstants.tasks}/$id',
      data: {
        'goalId': goalId,
        'title': title,
        'priority': priority,
        'status': statusStr,
        'estimateMinutes': estimateMinutes,
        'dueDate': dueDate?.toIso8601String(),
        'note': note,
        'taskType': taskType?.name,
        'recurringFrequency': recurringFrequency,
        'recurringTime': recurringTime,
        'subTasks': subTasks,
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Task.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '更新任务失败');
  }

  Future<Task> completeTask(int id) async {
    final response = await _apiClient.post('${ApiConstants.tasks}/$id/complete');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Task.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '完成任务失败');
  }

  Future<Task> uncompleteTask(int id) async {
    final response = await _apiClient.post('${ApiConstants.tasks}/$id/uncomplete');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Task.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '取消完成任务失败');
  }

  Future<void> deleteTask(int id) async {
    final response = await _apiClient.delete('${ApiConstants.tasks}/$id');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] != 200) {
      throw ApiException(message: data['message'] ?? '删除任务失败');
    }
  }

  // 批量创建子任务 - 粘贴模式
  Future<Task> batchCreateSubTasksPaste(int taskId, List<String> items) async {
    final response = await _apiClient.post(
      '${ApiConstants.tasks}/$taskId/subtasks/batch',
      data: {
        'mode': 'PASTE',
        'items': items,
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Task.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '批量创建子任务失败');
  }

  // 批量创建子任务 - 序列模式
  Future<Task> batchCreateSubTasksSequence(
    int taskId, {
    required String prefix,
    String suffix = '',
    int count = 10,
    int startAt = 1,
    String placeholder = '{n}',
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.tasks}/$taskId/subtasks/batch',
      data: {
        'mode': 'SEQUENCE',
        'prefix': prefix,
        'suffix': suffix,
        'count': count,
        'startAt': startAt,
        'placeholder': placeholder,
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Task.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '批量创建子任务失败');
  }

  // 切换子任务状态
  Future<Task> toggleSubTask(int taskId, int subTaskId) async {
    final response = await _apiClient.patch(
      '${ApiConstants.tasks}/$taskId/subtasks/$subTaskId/toggle',
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Task.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '切换子任务状态失败');
  }

  // 添加单个子任务
  Future<Task> addSubTask(int taskId, String title) async {
    final response = await _apiClient.post(
      '${ApiConstants.tasks}/$taskId/subtasks/batch',
      data: {
        'mode': 'PASTE',
        'items': [title],
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Task.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '添加子任务失败');
  }

  // 批量添加多个子任务（新增的）
  Future<Task> batchAddSubTasks(int taskId, List<String> titles) async {
    final response = await _apiClient.post(
      '${ApiConstants.tasks}/$taskId/subtasks/batch',
      data: {
        'mode': 'PASTE',
        'items': titles,
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return Task.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '批量添加子任务失败');
  }
}