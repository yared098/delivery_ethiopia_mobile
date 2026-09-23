import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/error_helper.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.storage});

  final AuthRemoteDataSource remote;
  final SecureStorage storage;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on DioException catch (e) {
      return Left(Failure(friendlyError(e), statusCode: e.response?.statusCode));
    } on ApiException catch (e) {
      return Left(Failure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  String _encodeAccount(Account a) => jsonEncode({
    'id': a.id,
    'phone': a.phone,
    'name': a.name,
    'email': a.email,
    'defaultAddress': a.defaultAddress,
    'defaultLat': a.defaultLat,
    'defaultLng': a.defaultLng,
    'phoneVerified': a.phoneVerified,
    'createdAt': a.createdAt?.toIso8601String(),
  });

  Future<void> _persist(SessionRaw raw) async {
    await storage.saveTokens(access: raw.accessToken, refresh: raw.refreshToken);
    await storage.saveAccountJson(_encodeAccount(raw.account));
  }

  @override
  Future<Either<Failure, void>> requestOtp(String phone) =>
      _guard(() => remote.requestOtp(phone));

  @override
  Future<Either<Failure, OtpVerifyResult>> verifyOtp({
    required String phone,
    required String code,
  }) => _guard(() async {
    final raw = await remote.verifyOtp(phone: phone, code: code);

    if (raw.registrationToken != null) {
      // New user → tell the UI to open the register page
      return OtpVerifyResult.registrationRequired(
        registrationToken: raw.registrationToken!,
        phone: raw.phone ?? phone,
      );
    }

    // Existing user → persist tokens and return the session
    final s = raw.session!;
    await _persist(s);
    return OtpVerifyResult.session(AuthSession(
      account: s.account,
      accessToken: s.accessToken,
      refreshToken: s.refreshToken,
      isNewUser: false,
    ));
  });

  @override
  Future<Either<Failure, AuthSession>> register({
    required String registrationToken,
    required String name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  }) => _guard(() async {
    final s = await remote.register(
      registrationToken: registrationToken,
      name: name,
      email: email,
      defaultAddress: defaultAddress,
      defaultLat: defaultLat,
      defaultLng: defaultLng,
    );
    await _persist(s);
    return AuthSession(
      account: s.account,
      accessToken: s.accessToken,
      refreshToken: s.refreshToken,
      isNewUser: true,
    );
  });

  @override
  Future<Either<Failure, void>> logout() => _guard(() async {
    final rt = await storage.refreshToken;
    if (rt != null) {
      try { await remote.logout(rt); } catch (_) {}
    }
    await storage.clear();
  });

  @override
  Future<Either<Failure, void>> logoutAll() => _guard(() async {
    try { await remote.logoutAll(); } catch (_) {}
    await storage.clear();
  });

  @override
  Future<Either<Failure, Account>> me() => _guard(() async {
    final a = await remote.me();
    await storage.saveAccountJson(_encodeAccount(a));
    return a;
  });

  @override
  Future<Either<Failure, Account>> updateProfile({
    String? name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  }) => _guard(() async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (defaultAddress != null) body['defaultAddress'] = defaultAddress;
    if (defaultLat != null) body['defaultLat'] = defaultLat;
    if (defaultLng != null) body['defaultLng'] = defaultLng;
    final a = await remote.updateProfile(body);
    await storage.saveAccountJson(_encodeAccount(a));
    return a;
  });
}
