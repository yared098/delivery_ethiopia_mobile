import '../../domain/entities/courier.dart';
import '../../domain/entities/courier_job.dart';
import '../../domain/entities/courier_earning.dart';

abstract class CourierHomeState {}

class CourierHomeInitial extends CourierHomeState {}

class CourierHomeLoading extends CourierHomeState {}

class CourierHomeLoaded extends CourierHomeState {
  final Courier courier;
  final List<CourierJob> jobs;
  final CourierJobsStats stats;

  CourierHomeLoaded({
    required this.courier,
    required this.jobs,
    required this.stats,
  });
}

class CourierHomeError extends CourierHomeState {
  final String message;
  CourierHomeError(this.message);
}
