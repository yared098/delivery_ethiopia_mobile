import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/courier_repository.dart';
import 'courier_home_event.dart';
import 'courier_home_state.dart';

class CourierHomeBloc extends Bloc<CourierHomeEvent, CourierHomeState> {
  final CourierRepository _repo;
  CourierHomeBloc(this._repo) : super(CourierHomeInitial()) {
    on<LoadCourierHome>(_onLoad);
    on<RefreshCourierHome>(_onLoad);
    on<ToggleCourierOnline>(_onToggleOnline);
  }

  Future<void> _onLoad(
    CourierHomeEvent event,
    Emitter<CourierHomeState> emit,
  ) async {
    emit(CourierHomeLoading());
    try {
      final results = await Future.wait([
        _repo.getMe(),
        _repo.listJobs(status: 'active'),
        _repo.getJobsStats(),
      ]);

      emit(CourierHomeLoaded(
        courier: results[0] as dynamic,
        jobs: (results[1] as List).cast(),
        stats: results[2] as dynamic,
      ));
    } catch (e) {
      emit(CourierHomeError(e.toString()));
    }
  }

  Future<void> _onToggleOnline(
    ToggleCourierOnline event,
    Emitter<CourierHomeState> emit,
  ) async {
    try {
      if (event.goOnline) {
        await _repo.goOnline(lat: event.lat, lng: event.lng);
      } else {
        await _repo.goOffline();
      }
      add(RefreshCourierHome());
    } catch (e) {
      emit(CourierHomeError(e.toString()));
    }
  }
}
