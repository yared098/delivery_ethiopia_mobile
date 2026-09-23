import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class Logout {
  Logout(this._repo);
  final AuthRepository _repo;
  Future<Either<Failure, void>> call() => _repo.logout();
}
