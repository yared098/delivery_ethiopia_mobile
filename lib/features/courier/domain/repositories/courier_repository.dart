import '../entities/courier.dart';
import '../entities/courier_job.dart';
import '../entities/courier_earning.dart';

abstract class CourierRepository {
  Future<Courier> getMe();
  Future<Courier> updateMe({String? name, String? email, String? vehiclePlate});
  Future<void> goOnline({required double lat, required double lng});
  Future<void> goOffline();
  Future<void> pushLocation({required double lat, required double lng});

  Future<List<CourierJob>> listJobs({String status = 'active'});
  Future<CourierJob> getJob(String id);
  Future<CourierJobsStats> getJobsStats();

  Future<List<CourierEarning>> listEarnings({String? status});
  Future<CourierEarningsSummary> getEarningsSummary();
}
