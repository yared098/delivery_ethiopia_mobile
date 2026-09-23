import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class RequestOtp {
  RequestOtp(this._repo);
  final AuthRepository _repo;
  Future<Either<Failure, void>> call(String phone) => _repo.requestOtp(phone);
}
