import '../../../core/api/api_client.dart';
import '../../../core/constants/constants.dart';
import '../../dashboard/domain/models.dart';

class StatsRepository {
  final ApiClient _apiClient;

  StatsRepository(this._apiClient);

  Future<DashboardStats> getOverview() async {
    final response = await _apiClient.get(ApiConstants.statsOverview);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return DashboardStats.fromJson(data['data']);
    }
    throw ApiException(message: data['message'] ?? '获取统计数据失败');
  }

  Future<Map<String, dynamic>> getLearningStats({int days = 7}) async {
    final response = await _apiClient.get(
      ApiConstants.statsLearning,
      queryParameters: {'days': days},
    );
    final responseData = response.data as Map<String, dynamic>;
    if (responseData['code'] == 200) {
      return responseData['data'] as Map<String, dynamic>;
    }
    throw ApiException(message: responseData['message'] ?? '获取学习统计失败');
  }

  Future<Map<String, dynamic>> getReviewStats() async {
    final response = await _apiClient.get(ApiConstants.statsReview);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return data['data'] as Map<String, dynamic>;
    }
    throw ApiException(message: data['message'] ?? '获取复习统计失败');
  }
}