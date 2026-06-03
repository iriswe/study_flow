import '../../../core/api/api_client.dart';
import '../../../core/constants/constants.dart';

class ReviewRepository {
  final ApiClient _apiClient;

  ReviewRepository(this._apiClient);

  Future<List<dynamic>> getTodayReviews() async {
    final response = await _apiClient.get(ApiConstants.todayReviews);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return data['data'] as List;
    }
    throw ApiException(message: data['message'] ?? '获取复习队列失败');
  }

  Future<void> review(int id, String rating) async {
    final apiValue = switch (rating) {
      '忘记' => 'FORGOT',
      '困难' => 'FUZZY',
      '一般' => 'GOOD',
      '简单' => 'EASY',
      _ => 'GOOD',
    };
    await _apiClient.post('${ApiConstants.reviews}/$id/review', data: {'response': apiValue});
  }

  Future<void> skip(int id) async {
    await _apiClient.post('${ApiConstants.reviews}/$id/skip');
  }

  Future<void> delay(int id, int days) async {
    await _apiClient.post('${ApiConstants.reviews}/$id/delay', queryParameters: {'days': days});
  }

  Future<Map<String, dynamic>> getReviewStats() async {
    final response = await _apiClient.get(ApiConstants.reviewStats);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return data['data'] as Map<String, dynamic>;
    }
    throw ApiException(message: data['message'] ?? '获取复习统计失败');
  }
}