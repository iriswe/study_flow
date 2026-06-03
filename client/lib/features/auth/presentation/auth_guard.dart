import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/constants.dart';

class AuthGuard {
  static const _storage = FlutterSecureStorage();

  static Future<bool> get isLoggedIn async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null;
  }
}