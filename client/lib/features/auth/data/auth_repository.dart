import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/constants.dart';
import '../../../core/auth/auth_global.dart';
import '../domain/models.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;
  final AuthGlobal _authGlobal;

  AuthRepository(this._apiClient, this._storage, this._authGlobal);

  Future<AuthResponse> login(String username, String password) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {'username': username, 'password': password},
    );

    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      final authResponse = AuthResponse.fromJson(data['data']);
      await _saveAuthData(authResponse);
      return authResponse;
    }
    throw ApiException(message: data['message'] ?? '登录失败');
  }

  Future<AuthResponse> register(String username, String password) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      data: {'username': username, 'password': password},
    );

    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200) {
      final authResponse = AuthResponse.fromJson(data['data']);
      await _saveAuthData(authResponse);
      return authResponse;
    }
    throw ApiException(message: data['message'] ?? '注册失败');
  }

  Future<void> logout() async {
    await _authGlobal.clearToken();
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.username);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null;
  }

  Future<String?> getToken() async {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<void> _saveAuthData(AuthResponse auth) async {
    await _storage.write(key: StorageKeys.accessToken, value: auth.token);
    await _storage.write(key: StorageKeys.userId, value: auth.userId.toString());
    await _storage.write(key: StorageKeys.username, value: auth.username);
  }
}