import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/account_kind.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.storage});

  final AuthRemoteDataSource remote;
  final SecureStorage storage; // 👈 typed — compiler will catch mismatches

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
      return Left(Failure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════
  // VERIFY OTP — smart routing + persist kind
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
            access: s.accessToken, refresh: s.refreshToken);
        await storage.saveAccountKind(AccountKind.courier); // 👈 NEW

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
      await storage.saveTokens(access: s.accessToken, refresh: s.refreshToken);
      await storage.saveAccountKind(AccountKind.customer); // 👈 NEW

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
      return Left(Failure(e.toString()));
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
          access: raw.accessToken, refresh: raw.refreshToken);
      await storage.saveAccountKind(AccountKind.customer); // 👈 NEW

      return Right(AuthSession(
        account: raw.account,
        accessToken: raw.accessToken,
        refreshToken: raw.refreshToken,
        isNewUser: true,
      ));
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e) {
      return Left(Failure(e.toString()));
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
      return Left(Failure(e.toString()));
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
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════
  // ME / UPDATE — route by stored kind
  // ══════════════════════════════════════════════════
  @override
  Future<Either<Failure, Account>> me() async {
    try {
      final kind = await storage.readAccountKind() ?? AccountKind.customer;
      final Account acc = kind == AccountKind.courier
          ? await remote.meCourier() // GET /courier/me
          : await remote.me(); // GET /auth/customer/me
      return Right(acc);
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    } catch (e) {
      return Left(Failure(e.toString()));
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
      final kind = await storage.readAccountKind() ?? AccountKind.customer;

      // Courier uses /courier/me (PATCH) with a different body shape
      // — delegate that to CourierRepository instead of doing it here.
      if (kind == AccountKind.courier) {
        return Left(Failure(
          'Use CourierRepository.updateMe() for courier profile edits.',
        ));
      }

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
      return Left(Failure(e.toString()));
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
    return Failure(message, statusCode: e.response?.statusCode);
  }
}
