import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

// Custom exceptions
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>> errors;
  ValidationException(this.message, this.errors);

  String get firstError {
    if (errors.isEmpty) return message;
    return errors.values.first.first;
  }

  @override
  String toString() => firstError;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(
      [this.message = 'Network error. Please check your connection.']);
  @override
  String toString() => message;
}

class UnauthorisedException implements Exception {
  final String message;
  UnauthorisedException(
      [this.message = 'Session expired. Please login again.']);
  @override
  String toString() => message;
}

// Navigation callback for 401 redirect
typedef OnUnauthorised = void Function();

class ApiService {
  late final Dio _dio;
  OnUnauthorised? onUnauthorised;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(seconds: AppConfig.connectTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.receiveTimeoutSeconds),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            debugPrint('→ ${options.method} ${options.path}');
            if (options.data != null) debugPrint('   Body: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
                '← ${response.statusCode} ${response.requestOptions.path}');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint(
                '✗ ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}');
          }

          final statusCode = error.response?.statusCode;

          if (statusCode == 401) {
            await StorageService.clearAll();
            onUnauthorised?.call();
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              error: UnauthorisedException(),
              type: DioExceptionType.badResponse,
            ));
            return;
          }

          if (statusCode == 422) {
            final data = error.response?.data;
            String message = 'Validation failed';
            Map<String, List<String>> errors = {};
            if (data is Map) {
              message = data['message'] as String? ?? message;
              final rawErrors = data['errors'];
              if (rawErrors is Map) {
                errors = rawErrors.map((k, v) {
                  final list = v is List
                      ? v.map((e) => e.toString()).toList()
                      : [v.toString()];
                  return MapEntry(k.toString(), list);
                });
              }
            }
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              error: ValidationException(message, errors),
              type: DioExceptionType.badResponse,
            ));
            return;
          }

          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError) {
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              error: NetworkException(),
              type: error.type,
            ));
            return;
          }

          handler.next(error);
        },
      ),
    );
  }

  /// Unwrap the exception from DioException
  static Exception _unwrap(dynamic e) {
    if (e is DioException && e.error != null) {
      final inner = e.error;
      if (inner is ApiException) return inner;
      if (inner is ValidationException) return inner;
      if (inner is NetworkException) return inner;
      if (inner is UnauthorisedException) return inner;
    }
    if (e is ApiException) return e;
    if (e is ValidationException) return e;
    if (e is NetworkException) return e;
    if (e is UnauthorisedException) return e;
    final statusCode = (e is DioException) ? e.response?.statusCode : null;
    final message = (e is DioException)
        ? (e.response?.data?['message'] as String? ??
            e.message ??
            'Unknown error')
        : e.toString();
    return ApiException(message, statusCode: statusCode);
  }

  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      throw _unwrap(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } catch (e) {
      throw _unwrap(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } catch (e) {
      throw _unwrap(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } catch (e) {
      throw _unwrap(e);
    }
  }

  /// For PDF downloads — returns raw bytes
  Future<List<int>> getBytes(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? [];
    } catch (e) {
      throw _unwrap(e);
    }
  }
}
