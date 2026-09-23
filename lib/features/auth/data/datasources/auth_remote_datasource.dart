import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/account_model.dart';

typedef SessionRaw = ({
  AccountModel account,
  String accessToken,
  String refreshToken,
});

typedef VerifyRaw = ({
  SessionRaw? session,
  String? registrationToken,
  String? phone,
});

abstract class AuthRemoteDataSource {
  Future<void> requestOtp(String phone);
  Future<VerifyRaw> verifyOtp({required String phone, required String code});
  Future<SessionRaw> register({
    required String registrationToken,
    required String name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  });
  Future<void> logout(String refreshToken);
  Future<void> logoutAll();
  Future<AccountModel> me();
  Future<AccountModel> updateProfile(Map<String, dynamic> body);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<void> requestOtp(String phone) async {
    await _dio.post(ApiConstants.requestOtp, data: {'phone': phone});
  }

  @override
  Future<VerifyRaw> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final res = await _dio.post(
      ApiConstants.verifyOtp,
      data: {'phone': phone, 'code': code},
    );
    final data = res.data as Map<String, dynamic>;

    // ── Case A: new user → registration required ──
    // Server returns: { isNewUser:true, requiresRegistration:true,
    //                   registrationToken, phone, message }
    if (data['requiresRegistration'] == true ||
        data['registrationToken'] != null) {
      return (
        session: null,
        registrationToken: data['registrationToken'] as String?,
        phone: data['phone'] as String?,
      );
    }

    // ── Case B: existing user → full session ──
    // Server returns: { isNewUser:false, account, accountType,
    //                   accessToken, refreshToken }
    final accountJson = data['account'];
    if (accountJson is! Map<String, dynamic>) {
      throw StateError(
        'Unexpected verify response: no account, no registrationToken. '
        'Got keys: ${data.keys.toList()}',
      );
    }

    return (
      session: (
        account: AccountModel.fromJson(accountJson),
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      ),
      registrationToken: null,
      phone: null,
    );
  }

  @override
  Future<SessionRaw> register({
    required String registrationToken,
    required String name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  }) async {
    final body = <String, dynamic>{
      'registrationToken': registrationToken,
      'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
      if (defaultAddress != null && defaultAddress.isNotEmpty)
        'defaultAddress': defaultAddress,
      if (defaultLat != null) 'defaultLat': defaultLat,
      if (defaultLng != null) 'defaultLng': defaultLng,
    };

    final res = await _dio.post(ApiConstants.register, data: body);
    final data = res.data as Map<String, dynamic>;

    return (
      account: AccountModel.fromJson(data['account'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _dio.post(ApiConstants.logout, data: {'refreshToken': refreshToken});
  }

  @override
  Future<void> logoutAll() async {
    await _dio.post(ApiConstants.logoutAll);
  }

  @override
  Future<AccountModel> me() async {
    final res = await _dio.get(ApiConstants.me);
    return AccountModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<AccountModel> updateProfile(Map<String, dynamic> body) async {
    final res = await _dio.patch(ApiConstants.me, data: body);
    return AccountModel.fromJson(res.data as Map<String, dynamic>);
  }
}
