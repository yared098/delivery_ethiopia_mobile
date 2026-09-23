import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class RegisterCustomer {
  RegisterCustomer(this._repo);
  final AuthRepository _repo;

  Future<Either<Failure, AuthSession>> call({
    required String registrationToken,
    required String name,
    String? email,
    String? defaultAddress,
    double? defaultLat,
    double? defaultLng,
  }) => _repo.register(
    registrationToken: registrationToken,
    name: name,
    email: email,
    defaultAddress: defaultAddress,
    defaultLat: defaultLat,
    defaultLng: defaultLng,
  );
}
