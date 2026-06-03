import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AuthGlobal {
  final FlutterSecureStorage _storage;

  AuthGlobal(this._storage);

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  void setLoggedIn(bool value) {
    _isLoggedIn = value;
  }

  Future<void> clearToken() async {
    await _storage.delete(key: StorageKeys.accessToken);
    _isLoggedIn = false;
  }

  Future<bool> checkLoggedIn() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    _isLoggedIn = token != null && token.isNotEmpty;
    return _isLoggedIn;
  }
}
