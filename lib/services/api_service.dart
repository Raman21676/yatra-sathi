import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// API Service
/// Handles all HTTP requests to the backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final StorageService _storage = StorageService();

  /// Initialize Dio with configurations
  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_logInterceptor());
  }

  /// Authentication Interceptor
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final token = await _storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized
        if (error.response?.statusCode == 401) {
          await _storage.clearToken();
          // You can add navigation to login screen here
        }
        return handler.next(error);
      },
    );
  }

  /// Logging Interceptor
  Interceptor _logInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          print('╔═══════════════════════════════════════════════════════════╗');
          print('║ REQUEST                                                   ║');
          print('╠═══════════════════════════════════════════════════════════╣');
          print('║ ${options.method.toUpperCase()} ${options.path}');
          print('║ Headers: ${options.headers}');
          print('║ Data: ${options.data}');
          print('╚═══════════════════════════════════════════════════════════╝');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('╔═══════════════════════════════════════════════════════════╗');
          print('║ RESPONSE                                                  ║');
          print('╠═══════════════════════════════════════════════════════════╣');
          print('║ Status: ${response.statusCode}');
          print('║ Data: ${response.data}');
          print('╚═══════════════════════════════════════════════════════════╝');
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('╔═══════════════════════════════════════════════════════════╗');
          print('║ ERROR                                                     ║');
          print('╠═══════════════════════════════════════════════════════════╣');
          print('║ Status: ${error.response?.statusCode}');
          print('║ Message: ${error.message}');
          print('║ Data: ${error.response?.data}');
          print('╚═══════════════════════════════════════════════════════════╝');
        }
        return handler.next(error);
      },
    );
  }

  // ==================== HTTP METHODS ====================

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file with multipart/form-data
  Future<Response> uploadFile(
    String path, {
    required File file,
    String fieldName = 'image',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(file.path),
        if (additionalData != null) ...additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload multiple files
  Future<Response> uploadMultipleFiles(
    String path, {
    required List<File> files,
    String fieldName = 'images',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final List<MultipartFile> multipartFiles = [];
      for (var file in files) {
        multipartFiles.add(await MultipartFile.fromFile(file.path));
      }

      final formData = FormData.fromMap({
        fieldName: multipartFiles,
        if (additionalData != null) ...additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle API errors
  Exception _handleError(DioException error) {
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        
        if (data != null && data is Map && data['message'] != null) {
          message = data['message'];
        } else {
          switch (statusCode) {
            case 400:
              message = 'Bad request. Please check your input.';
              break;
            case 401:
              message = 'Unauthorized. Please login again.';
              break;
            case 403:
              message = 'Access denied. You do not have permission.';
              break;
            case 404:
              message = 'Resource not found.';
              break;
            case 422:
              message = 'Validation failed. Please check your input.';
              break;
            case 500:
              message = 'Server error. Please try again later.';
              break;
            default:
              message = 'Something went wrong. Please try again.';
          }
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
        break;
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          message = 'No internet connection. Please check your network.';
        } else {
          message = 'An unexpected error occurred.';
        }
        break;
      default:
        message = 'Something went wrong. Please try again.';
    }

    return ApiException(message, statusCode: error.response?.statusCode);
  }

  /// Check if server is reachable
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(ApiConstants.health);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
