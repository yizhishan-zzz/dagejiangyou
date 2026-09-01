import 'package:dio/dio.dart';

import '../config/app_settings.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._settings)
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 12),
          responseType: ResponseType.json,
        ),
      );

  final AppSettings _settings;
  final Dio _dio;
  Future<bool>? _refreshing;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
  }) {
    return _request(
      () => _dio.get<dynamic>(
        _url(path),
        queryParameters: queryParameters,
        options: _options(withAuth: withAuth),
      ),
      withAuth: withAuth,
    );
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
  }) {
    return _request(
      () => _dio.post<dynamic>(
        _url(path),
        data: data,
        queryParameters: queryParameters,
        options: _options(withAuth: withAuth),
      ),
      withAuth: withAuth,
    );
  }

  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
  }) {
    return _request(
      () => _dio.put<dynamic>(
        _url(path),
        data: data,
        queryParameters: queryParameters,
        options: _options(withAuth: withAuth),
      ),
      withAuth: withAuth,
    );
  }

  Future<dynamic> _request(
    Future<Response<dynamic>> Function() request, {
    required bool withAuth,
    bool hasRetried = false,
  }) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (error) {
      if (withAuth &&
          !hasRetried &&
          error.response?.statusCode == 401 &&
          await _refreshAccessToken()) {
        return _request(request, withAuth: withAuth, hasRetried: true);
      }
      throw _mapError(error);
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_settings.refreshToken.trim().isEmpty) {
      await _settings.clearSession();
      return false;
    }
    final running = _refreshing;
    if (running != null) {
      return running;
    }
    final future = _performRefresh();
    _refreshing = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshing, future)) {
        _refreshing = null;
      }
    }
  }

  Future<bool> _performRefresh() async {
    try {
      final response = await _dio.post<dynamic>(
        _url('/users/auth/refresh'),
        data: {'refreshToken': _settings.refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return false;
      }
      final accessToken = data['accessToken']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? '';
      if (accessToken.isEmpty || refreshToken.isEmpty) {
        return false;
      }
      await _settings.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 400 ||
          error.response?.statusCode == 401 ||
          error.response?.statusCode == 404) {
        await _settings.clearSession();
      }
      return false;
    }
  }

  String _url(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return '${_settings.sanitizedBaseUrl}$normalized';
  }

  Options _options({required bool withAuth}) {
    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (withAuth && _settings.accessToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_settings.accessToken.trim()}';
    }
    return Options(headers: headers);
  }

  ApiException _mapError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        data['message']?.toString() ?? '请求失败，请稍后重试',
        statusCode: error.response?.statusCode,
      );
    }
    return ApiException(
      error.response == null ? '网络连接失败，请检查服务是否可用' : '请求失败，请稍后重试',
      statusCode: error.response?.statusCode,
    );
  }
}
