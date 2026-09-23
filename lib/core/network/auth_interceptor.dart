import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

typedef OnLogout = Future<void> Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage storage,
    required Dio refreshDio,
    required OnLogout onLogout,
  })  : _storage = storage,
        _refreshDio = refreshDio,
        _onLogout = onLogout;

  final SecureStorage _storage;
  final Dio _refreshDio;
  final OnLogout _onLogout;

  Future<String?>? _refreshFuture; // single-flight refresh

  static const _skipAuthPaths = [
    ApiConstants.requestOtp,
    ApiConstants.verifyOtp,
    ApiConstants.refresh,
  ];

  bool _isPublic(String path) =>
      _skipAuthPaths.any((p) => path.contains(p));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final token = await _storage.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (status == 401 && !_isPublic(path) && !alreadyRetried) {
      try {
        final newToken = await _refreshToken();
        if (newToken == null) {
          await _onLogout();
          return handler.next(err);
        }

        final opts = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newToken'
          ..extra['retried'] = true;

        final response = await Dio(BaseOptions(baseUrl: opts.baseUrl)).fetch(opts);
        return handler.resolve(response);
      } catch (_) {
        await _onLogout();
        return handler.next(err);
      }
    }
    handler.next(err);
  }

  Future<String?> _refreshToken() {
    return _refreshFuture ??= _doRefresh()
        .whenComplete(() => _refreshFuture = null);
  }

  Future<String?> _doRefresh() async {
    final refresh = await _storage.refreshToken;
    if (refresh == null || refresh.isEmpty) return null;

    final res = await _refreshDio.post(
      ApiConstants.refresh,
      data: {'refreshToken': refresh},
    );

    final newAccess  = res.data['accessToken']  as String?;
    final newRefresh = res.data['refreshToken'] as String?;
    if (newAccess == null || newRefresh == null) return null;

    await _storage.saveTokens(access: newAccess, refresh: newRefresh);
    return newAccess;
  }
}
