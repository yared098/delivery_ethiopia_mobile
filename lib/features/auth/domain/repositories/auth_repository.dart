// import 'package:dartz/dartz.dart';
// import '../../../../core/errors/failure.dart';
// import '../entities/account.dart';

// class AuthSession {
//   const AuthSession({
//     required this.account,
//     required this.accessToken,
//     required this.refreshToken,
//     this.isNewUser = false,
//   });
//   final Account account;
//   final String accessToken;
//   final String refreshToken;
//   final bool isNewUser;
// }

// /// Result of POST /auth/customer/otp/verify
// ///
// /// Either:
// ///   - [OtpVerifyResult.session]                 — existing user; tokens present
// ///   - [OtpVerifyResult.registrationRequired]    — new user; needs register step
// class OtpVerifyResult {
//   const OtpVerifyResult.session(AuthSession this.session)
//       : registrationToken = null,
//         phone = null;

//   const OtpVerifyResult.registrationRequired({
//     required String this.registrationToken,
//     required String this.phone,
//   }) : session = null;

//   final AuthSession? session;
//   final String? registrationToken;
//   final String? phone;

//   bool get isRegistrationRequired => registrationToken != null;
// }

// abstract class AuthRepository {
//   Future<Either<Failure, void>> requestOtp(String phone);

//   Future<Either<Failure, OtpVerifyResult>> verifyOtp({
//     required String phone,
//     required String code,
//   });

//   /// POST /auth/customer/register — finish registration for a new user.
//   Future<Either<Failure, AuthSession>> register({
//     required String registrationToken,
//     required String name,
//     String? email,
//     String? defaultAddress,
//     double? defaultLat,
//     double? defaultLng,
//   });

//   Future<Either<Failure, void>> logout();
//   Future<Either<Failure, void>> logoutAll();
//   Future<Either<Failure, Account>> me();

//   Future<Either<Failure, Account>> updateProfile({
//     String? name,
//     String? email,
//     String? defaultAddress,
//     double? defaultLat,
//     double? defaultLng,
//   });
// }

import 'package:dartz/dartz.dart';
import 'package:deliver_ethiopia/features/auth/domain/usecases/account_kind.dart';
import '../../../../core/errors/failure.dart';
import '../entities/account.dart';

class AuthSession {
  const AuthSession({
    required this.account,
    required this.accessToken,
    required this.refreshToken,
    this.isNewUser = false,
  });
  final Account account;
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
}

/// Result of POST /auth/customer/otp/verify OR /auth/courier/otp/verify
///
/// Either:
///   - [OtpVerifyResult.session]                 — user found; tokens present
///   - [OtpVerifyResult.registrationRequired]    — new customer; needs register
///
/// [kind] tells the app which home screen to show.
class OtpVerifyResult {
  const OtpVerifyResult.session(
    AuthSession this.session, {
    this.kind = AccountKind.customer, // ← NEW
  })  : registrationToken = null,
        phone = null;

  const OtpVerifyResult.registrationRequired({
    required String this.registrationToken,
    required String this.phone,
  })  : session = null,
        kind = AccountKind.customer; // ← NEW

  final AuthSession? session;
  final String? registrationToken;
  final String? phone;

  /// NEW — customer or courier
  final AccountKind kind;

  bool get isRegistrationRequired => registrationToken != null;
}

abstract class AuthRepository {
  Future<Either<Failure, void>> requestOtp(String phone);

  Future<Either<Failure, OtpVerifyResult>> verifyOtp({
    required String phone,
    required String code,
  });

  /// POST /auth/customer/register — finish registration for a new user.
  Future<Either<Failure, AuthSession>> register({
    required String registrationToken,
    required String name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  });

  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> logoutAll();
  Future<Either<Failure, Account>> me();

  Future<Either<Failure, Account>> updateProfile({
    String? name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  });
}
