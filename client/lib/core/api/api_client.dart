import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';
import '../auth/auth_global.dart';
import '../di/injection.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  final AuthGlobal _authGlobal;

  ApiClient(this._storage, this._authGlobal) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: StorageKeys.accessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _authGlobal.clearToken();
            final ctx = rootNavigatorKey.currentContext;
            if (ctx != null && ctx.mounted) {
              Navigator.of(ctx).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.put<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath,
    String fileName,
    {bool useJsonContentType = false}
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final options = useJsonContentType
        ? Options(headers: {'Content-Type': 'application/json'})
        : null;
    return _dio.post<T>(path, data: formData, options: options);
  }

  Future<String> uploadImage(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/upload/image',
      data: formData,
    );
    final data = response.data;
    if (data != null && data['code'] == 200 && data['data'] != null) {
      return data['data']['fileUrl'] as String;
    }
    throw ApiException(message: data?['message'] ?? '图片上传失败');
  }
}

class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final DateTime timestamp;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    required this.timestamp,
  });

  bool get isSuccess => code == 200;

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException({this.statusCode, required this.message});

  factory ApiException.fromDioError(DioException error) {
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = '连接超时';
        break;
      case DioExceptionType.receiveTimeout:
        message = '响应超时';
        break;
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        } else {
          message = '服务器错误: ${error.response?.statusCode}';
        }
        break;
      case DioExceptionType.cancel:
        message = '请求取消';
        break;
      default:
        message = '网络错误';
    }
    return ApiException(
      statusCode: error.response?.statusCode,
      message: message,
    );
  }

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';
}
