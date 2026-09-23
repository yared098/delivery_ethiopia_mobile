import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';

class DeviceTokenService {
  DeviceTokenService(this._client);
  final DioClient _client;

  Dio get _dio => _client.dio;

  /// Register (or refresh) the device's FCM token with the backend.
  Future<bool> register(String token) async {
    if (token.isEmpty) return false;
    final platform = platformName();
    try {
      final res = await _dio.post(
        ApiConstants.deviceToken,
        data: {'token': token, 'platform': platform},
      );
      if (kDebugMode) {
        debugPrint('🔔 device-token registered: '
            'id=${res.data['id']} platform=${res.data['platform']}');
      }
      return true;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('🔔 device-token register failed: '
            '${e.response?.statusCode} ${e.response?.data ?? e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('🔔 device-token register error: $e');
      return false;
    }
  }

  /// Remove the token from the backend (call on logout).
  Future<bool> remove(String token) async {
    if (token.isEmpty) return false;
    try {
      await _dio.post(
        ApiConstants.deviceTokenRemove,
        data: {'token': token},
      );
      if (kDebugMode) debugPrint('🔔 device-token removed');
      return true;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('🔔 device-token remove failed: '
            '${e.response?.statusCode} ${e.response?.data ?? e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('🔔 device-token remove error: $e');
      return false;
    }
  }

  /// Returns "android", "ios" or "web".
  static String platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }
}
