import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';

enum DeviceAccount { customer, courier }

class DeviceTokenService {
  DeviceTokenService(this._client);
  final DioClient _client;

  Dio get _dio => _client.dio;

  DeviceAccount _account = DeviceAccount.customer;

  /// Called by AuthBloc on login to switch between customer / courier endpoints.
  void setAccount(DeviceAccount a) {
    _account = a;
    if (kDebugMode) debugPrint('🔔 device account = $a');
  }

  String get _registerEndpoint => _account == DeviceAccount.courier
      ? ApiConstants.courierDeviceToken
      : ApiConstants.deviceToken;

  String get _removeEndpoint => _account == DeviceAccount.courier
      ? ApiConstants.courierDeviceTokenRemove
      : ApiConstants.deviceTokenRemove;

  Future<bool> register(String token) async {
    if (token.isEmpty) return false;
    final platform = platformName();
    try {
      final res = await _dio.post(
        _registerEndpoint,
        data: {'token': token, 'platform': platform},
      );
      if (kDebugMode) {
        debugPrint('🔔 device-token registered ($_account): '
            'id=${res.data['id']} platform=${res.data['platform']}');
      }
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return false;
      if (kDebugMode) {
        debugPrint('🔔 device-token register failed ($_account): '
            '${e.response?.statusCode}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('🔔 device-token register error: $e');
      return false;
    }
  }

  Future<bool> remove(String token) async {
    if (token.isEmpty) return false;
    try {
      await _dio.post(
        _removeEndpoint,
        data: {'token': token},
      );
      if (kDebugMode) debugPrint('🔔 device-token removed ($_account)');
      return true;
    } on DioException catch (e) {
      // 401 during logout is expected — silent.
      if (e.response?.statusCode == 401) return false;
      if (kDebugMode) {
        debugPrint('🔔 device-token remove failed ($_account): '
            '${e.response?.statusCode}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('🔔 device-token remove error: $e');
      return false;
    }
  }

  static String platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }
}
