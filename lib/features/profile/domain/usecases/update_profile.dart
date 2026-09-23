import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../auth/domain/entities/account.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class UpdateProfile {
  UpdateProfile(this._repo);
  final AuthRepository _repo;

  Future<Either<Failure, Account>> call({
    String? name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  }) => _repo.updateProfile(
    name: name,
    email: email,
    defaultAddress: defaultAddress,
    defaultLat: defaultLat,
    defaultLng: defaultLng,
  );
}
