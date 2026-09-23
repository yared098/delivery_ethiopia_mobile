import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class VerifyOtp {
  VerifyOtp(this._repo);
  final AuthRepository _repo;
  Future<Either<Failure, OtpVerifyResult>> call({
    required String phone,
    required String code,
  }) => _repo.verifyOtp(phone: phone, code: code);
}
