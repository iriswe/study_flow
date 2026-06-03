import '../../../core/api/api_client.dart';
import '../../../core/constants/constants.dart';

class SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepository(this._apiClient);

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _apiClient.get(ApiConstants.settings);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return data['data'] as Map<String, dynamic>;
    }
    throw ApiException(message: data['message'] ?? '获取设置失败');
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> updates) async {
    final response = await _apiClient.put(ApiConstants.settings, data: updates);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return data['data'] as Map<String, dynamic>;
    }
    throw ApiException(message: data['message'] ?? '更新设置失败');
  }

  Future<Map<String, dynamic>> syncSettings() async {
    final response = await _apiClient.post(ApiConstants.settingsSync);
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      return data['data'] as Map<String, dynamic>;
    }
    throw ApiException(message: data['message'] ?? '同步失败');
  }
}