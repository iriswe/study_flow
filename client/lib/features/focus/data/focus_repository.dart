import '../../../core/api/api_client.dart';
import '../../../core/constants/constants.dart';

class FocusSession {
  final int id;
  final int? taskId;
  final String? taskTitle;
  final int duration;
  final int? actualDuration;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  FocusSession({
    required this.id,
    this.taskId,
    this.taskTitle,
    required this.duration,
    this.actualDuration,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as int,
      taskId: json['taskId'] as int?,
      taskTitle: json['taskTitle'] as String?,
      duration: json['duration'] as int? ?? 0,
      actualDuration: json['actualDuration'] as int?,
      status: json['status'] as String? ?? 'PENDING',
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt'] as String) : null,
      endedAt: json['endedAt'] != null ? DateTime.tryParse(json['endedAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class FocusRepository {
  final ApiClient _apiClient;

  FocusRepository(this._apiClient);

  Future<List<FocusSession>> getSessions() async {
    final response = await _apiClient.get(ApiConstants.focus);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return (data['data'] as List)
          .map((e) => FocusSession.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(message: data['message'] ?? '获取专注记录失败');
  }

  Future<List<FocusSession>> getTodaySessions() async {
    final response = await _apiClient.get(ApiConstants.focusToday);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return (data['data'] as List)
          .map((e) => FocusSession.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(message: data['message'] ?? '获取今日专注记录失败');
  }

  Future<FocusSession> createSession(int duration, {int? taskId}) async {
    final response = await _apiClient.post(
      ApiConstants.focus,
      data: {'duration': duration, 'taskId': taskId},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return FocusSession.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw ApiException(message: data['message'] ?? '创建专注会话失败');
  }

  Future<void> startSession(int id) async {
    await _apiClient.post('${ApiConstants.focus}/$id/start');
  }

  Future<void> completeSession(int id, int actualDuration) async {
    await _apiClient.post(
      '${ApiConstants.focus}/$id/complete',
      queryParameters: {'actualDuration': actualDuration},
    );
  }
}
