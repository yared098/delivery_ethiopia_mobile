import '../../domain/entities/courier.dart';
import '../../domain/entities/courier_job.dart';
import '../../domain/entities/courier_earning.dart';
import '../../domain/repositories/courier_repository.dart';
import '../datasources/courier_remote_datasource.dart';

class CourierRepositoryImpl implements CourierRepository {
  final CourierRemoteDataSource _remote;
  CourierRepositoryImpl(this._remote);

  @override
  Future<Courier> getMe() => _remote.getMe();

  @override
  Future<Courier> updateMe({
    String? name,
    String? email,
    String? vehiclePlate,
  }) =>
      _remote.updateMe(
        name: name,
        email: email,
        vehiclePlate: vehiclePlate,
      );

  @override
  Future<void> goOnline({required double lat, required double lng}) =>
      _remote.goOnline(lat: lat, lng: lng);

  @override
  Future<void> goOffline() => _remote.goOffline();

  @override
  Future<void> pushLocation({required double lat, required double lng}) =>
      _remote.pushLocation(lat: lat, lng: lng);

  @override
  Future<List<CourierJob>> listJobs({String status = 'active'}) =>
      _remote.listJobs(status: status);

  @override
  Future<CourierJob> getJob(String id) => _remote.getJob(id);

  @override
  Future<CourierJobsStats> getJobsStats() async {
    final raw = await _remote.getJobsStats();
    final today = raw['today'] as Map<String, dynamic>? ?? {};
    final all = raw['allTime'] as Map<String, dynamic>? ?? {};

    return CourierJobsStats(
      todayAssigned: today['assigned'] as int? ?? 0,
      todayCompleted: today['completed'] as int? ?? 0,
      todayInProgress: today['inProgress'] as int? ?? 0,
      todayEarnings: (today['earnings'] as num?)?.toDouble() ?? 0,
      allTotalDeliveries: all['totalDeliveries'] as int? ?? 0,
      allTotalFailed: all['totalFailed'] as int? ?? 0,
      allRating: (all['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }

  @override
  Future<List<CourierEarning>> listEarnings({String? status}) =>
      _remote.listEarnings(status: status);

  @override
  Future<CourierEarningsSummary> getEarningsSummary() async {
    final raw = await _remote.getEarningsSummary();
    return CourierEarningsSummary(
      pending: (raw['pending'] as num?)?.toDouble() ?? 0,
      released: (raw['released'] as num?)?.toDouble() ?? 0,
      paid: (raw['paid'] as num?)?.toDouble() ?? 0,
      currency: raw['currency'] as String? ?? 'ETB',
    );
  }
}
