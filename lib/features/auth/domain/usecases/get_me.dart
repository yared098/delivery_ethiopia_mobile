import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/account.dart';
import '../repositories/auth_repository.dart';

class GetMe {
  GetMe(this._repo);
  final AuthRepository _repo;
  Future<Either<Failure, Account>> call() => _repo.me();
}
