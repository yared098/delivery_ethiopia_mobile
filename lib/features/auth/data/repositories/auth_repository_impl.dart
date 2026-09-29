// import 'dart:convert';
// import 'package:dartz/dartz.dart';
// import 'package:dio/dio.dart';
// import '../../../../core/errors/failure.dart';
// import '../../../../core/network/api_exception.dart';
// import '../../../../core/storage/secure_storage.dart';
// import '../../../../core/utils/error_helper.dart';
// import '../../domain/entities/account.dart';
// import '../../domain/repositories/auth_repository.dart';
// import '../datasources/auth_remote_datasource.dart';

// class AuthRepositoryImpl implements AuthRepository {
//   AuthRepositoryImpl({required this.remote, required this.storage});

//   final AuthRemoteDataSource remote;
//   final SecureStorage storage;

//   Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
//     try {
//       return Right(await run());
//     } on DioException catch (e) {
//       return Left(Failure(friendlyError(e), statusCode: e.response?.statusCode));
//     } on ApiException catch (e) {
//       return Left(Failure(e.message, statusCode: e.statusCode));
//     } catch (e) {
//       return Left(Failure(e.toString()));
//     }
//   }

//   String _encodeAccount(Account a) => jsonEncode({
//     'id': a.id,
//     'phone': a.phone,
//     'name': a.name,
//     'email': a.email,
//     'defaultAddress': a.defaultAddress,
//     'defaultLat': a.defaultLat,
//     'defaultLng': a.defaultLng,
//     'phoneVerified': a.phoneVerified,
//     'createdAt': a.createdAt?.toIso8601String(),
//   });

//   Future<void> _persist(SessionRaw raw) async {
//     await storage.saveTokens(access: raw.accessToken, refresh: raw.refreshToken);
//     await storage.saveAccountJson(_encodeAccount(raw.account));
//   }

//   @override
//   Future<Either<Failure, void>> requestOtp(String phone) =>
//       _guard(() => remote.requestOtp(phone));

//   @override
//   Future<Either<Failure, OtpVerifyResult>> verifyOtp({
//     required String phone,
//     required String code,
//   }) => _guard(() async {
//     final raw = await remote.verifyOtp(phone: phone, code: code);

//     if (raw.registrationToken != null) {
//       // New user → tell the UI to open the register page
//       return OtpVerifyResult.registrationRequired(
//         registrationToken: raw.registrationToken!,
//         phone: raw.phone ?? phone,
//       );
//     }

//     // Existing user → persist tokens and return the session
//     final s = raw.session!;
//     await _persist(s);
//     return OtpVerifyResult.session(AuthSession(
//       account: s.account,
//       accessToken: s.accessToken,
//       refreshToken: s.refreshToken,
//       isNewUser: false,
//     ));
//   });

//   @override
//   Future<Either<Failure, AuthSession>> register({
//     required String registrationToken,
//     required String name,
//     String? email,
//     String? defaultAddress,
//     double? defaultLat,
//     double? defaultLng,
//   }) => _guard(() async {
//     final s = await remote.register(
//       registrationToken: registrationToken,
//       name: name,
//       email: email,
//       defaultAddress: defaultAddress,
//       defaultLat: defaultLat,
//       defaultLng: defaultLng,
//     );
//     await _persist(s);
//     return AuthSession(
//       account: s.account,
//       accessToken: s.accessToken,
//       refreshToken: s.refreshToken,
//       isNewUser: true,
//     );
//   });

//   @override
//   Future<Either<Failure, void>> logout() => _guard(() async {
//     final rt = await storage.refreshToken;
//     if (rt != null) {
//       try { await remote.logout(rt); } catch (_) {}
//     }
//     await storage.clear();
//   });

//   @override
//   Future<Either<Failure, void>> logoutAll() => _guard(() async {
//     try { await remote.logoutAll(); } catch (_) {}
//     await storage.clear();
//   });

//   @override
//   Future<Either<Failure, Account>> me() => _guard(() async {
//     final a = await remote.me();
//     await storage.saveAccountJson(_encodeAccount(a));
//     return a;
//   });

//   @override
//   Future<Either<Failure, Account>> updateProfile({
//     String? name,
//     String? email,
//     String? defaultAddress,
//     double? defaultLat,
//     double? defaultLng,
//   }) => _guard(() async {
//     final body = <String, dynamic>{};
//     if (name != null) body['name'] = name;
//     if (email != null) body['email'] = email;
//     if (defaultAddress != null) body['defaultAddress'] = defaultAddress;
//     if (defaultLat != null) body['defaultLat'] = defaultLat;
//     if (defaultLng != null) body['defaultLng'] = defaultLng;
//     final a = await remote.updateProfile(body);
//     await storage.saveAccountJson(_encodeAccount(a));
//     return a;
//   });
// }

import 'package:dartz/dartz.dart';
import 'package:deliver_ethiopia/features/auth/domain/usecases/account_kind.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.storage});

  final AuthRemoteDataSource remote;
  final dynamic storage;

  // ══════════════════════════════════════════════════
  // REQUEST OTP — smart routing
  // ══════════════════════════════════════════════════
  @override
  Future<Either<Failure, void>> requestOtp(String phone) async {
    try {
      final isCourier = await remote.isCourierPhone(phone);

      if (isCourier) {
        await remote.requestCourierOtp(phone);
      } else {
        await remote.requestOtp(phone);
      }

      return const Right(null);
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e) {
      return Left(Failure(e.toString())); // ← positional
    }
  }

  // ══════════════════════════════════════════════════
  // VERIFY OTP — smart routing
  // ══════════════════════════════════════════════════
  @override
  Future<Either<Failure, OtpVerifyResult>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final isCourier = await remote.isCourierPhone(phone);

      final VerifyRaw raw;
      if (isCourier) {
        raw = await remote.verifyCourierOtp(phone: phone, code: code);
      } else {
        raw = await remote.verifyOtp(phone: phone, code: code);
      }

      // ── Courier path ──
      if (isCourier) {
        final s = raw.session!;
        await storage.saveTokens(
          access: s.accessToken,
          refresh: s.refreshToken,
        );

        final session = AuthSession(
          account: s.account,
          accessToken: s.accessToken,
          refreshToken: s.refreshToken,
        );

        return Right(OtpVerifyResult.session(
          session,
          kind: AccountKind.courier,
        ));
      }

      // ── Customer path — registration required ──
      if (raw.registrationToken != null) {
        return Right(OtpVerifyResult.registrationRequired(
          registrationToken: raw.registrationToken!,
          phone: raw.phone ?? phone,
        ));
      }

      // ── Customer path — existing user ──
      final s = raw.session!;
      await storage.saveTokens(
        access: s.accessToken,
        refresh: s.refreshToken,
      );

      final session = AuthSession(
        account: s.account,
        accessToken: s.accessToken,
        refreshToken: s.refreshToken,
      );

      return Right(OtpVerifyResult.session(
        session,
        kind: AccountKind.customer,
      ));
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e) {
      return Left(Failure(e.toString())); // ← positional
    }
  }

  // ══════════════════════════════════════════════════
  // REGISTER (customer)
  // ══════════════════════════════════════════════════
  @override
  Future<Either<Failure, AuthSession>> register({
    required String registrationToken,
    required String name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  }) async {
    try {
      final raw = await remote.register(
        registrationToken: registrationToken,
        name: name,
        email: email,
        defaultAddress: defaultAddress,
        defaultLat: defaultLat,
        defaultLng: defaultLng,
      );
      await storage.saveTokens(
        access: raw.accessToken,
        refresh: raw.refreshToken,
      );
      return Right(AuthSession(
        account: raw.account,
        accessToken: raw.accessToken,
        refreshToken: raw.refreshToken,
        isNewUser: true,
      ));
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e) {
      return Left(Failure(e.toString())); // ← positional
    }
  }

  // ══════════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════════
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refresh = await storage.refreshToken;
      if (refresh != null) {
        try {
          await remote.logout(refresh);
        } catch (_) {}
      }
      await storage.clear();
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString())); // ← positional
    }
  }

  @override
  Future<Either<Failure, void>> logoutAll() async {
    try {
      await remote.logoutAll();
      await storage.clear();
      return const Right(null);
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    }
  }

  // ══════════════════════════════════════════════════
  // ME / UPDATE
  // ══════════════════════════════════════════════════
  @override
  Future<Either<Failure, Account>> me() async {
    try {
      return Right(await remote.me());
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e) {
      return Left(Failure(e.toString())); // ← positional
    }
  }

  @override
  Future<Either<Failure, Account>> updateProfile({
    String? name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (defaultAddress != null) body['defaultAddress'] = defaultAddress;
      if (defaultLat != null) body['defaultLat'] = defaultLat;
      if (defaultLng != null) body['defaultLng'] = defaultLng;

      return Right(await remote.updateProfile(body));
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e) {
      return Left(Failure(e.toString())); // ← positional
    }
  }

  // ─── Helper ───
  Failure _failureFromDio(DioException e) {
    final data = e.response?.data;
    String message = 'Network error';
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      message = m is String ? m : m.toString();
    }
    return Failure(message, statusCode: e.response?.statusCode); // ← positional
  }
}
