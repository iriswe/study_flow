import '../../../core/api/api_client.dart';
import '../../../core/constants/constants.dart';

class StudyLogRepository {
  final ApiClient _apiClient;

  StudyLogRepository(this._apiClient);

  Future<List<dynamic>> getStudyLogs({int page = 0, int size = 20}) async {
    final response = await _apiClient.get(
      ApiConstants.studyLogs,
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return data['data'] as List;
    }
    throw ApiException(message: data['message'] ?? '获取学习记录失败');
  }

  Future<List<dynamic>> getStudyLogsByGoalId(int goalId) async {
    final response = await _apiClient.get(
      ApiConstants.studyLogs,
      queryParameters: {'goalId': goalId},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return data['data'] as List;
    }
    throw ApiException(message: data['message'] ?? '获取学习记录失败');
  }

  Future<Map<String, dynamic>> getStudyLog(int id) async {
    final response = await _apiClient.get('${ApiConstants.studyLogs}/$id');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return data['data'] as Map<String, dynamic>;
    }
    throw ApiException(message: data['message'] ?? '获取学习记录失败');
  }

  Future<void> createStudyLog(Map<String, dynamic> logData) async {
    final response = await _apiClient.post(ApiConstants.studyLogs, data: logData);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] != 200) {
      throw ApiException(message: data['message'] ?? '创建学习记录失败');
    }
  }

  Future<void> deleteStudyLog(int id) async {
    final response = await _apiClient.delete('${ApiConstants.studyLogs}/$id');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] != 200) {
      throw ApiException(message: data['message'] ?? '删除学习记录失败');
    }
  }

  Future<void> updateStudyLog(int id, Map<String, dynamic> logData) async {
    final response = await _apiClient.put('${ApiConstants.studyLogs}/$id', data: logData);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] != 200) {
      throw ApiException(message: data['message'] ?? '更新学习记录失败');
    }
  }
}