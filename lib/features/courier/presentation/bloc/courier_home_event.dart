abstract class CourierHomeEvent {}

class LoadCourierHome extends CourierHomeEvent {}

class RefreshCourierHome extends CourierHomeEvent {}

class ToggleCourierOnline extends CourierHomeEvent {
  final double lat;
  final double lng;
  final bool goOnline;
  ToggleCourierOnline({
    required this.lat,
    required this.lng,
    required this.goOnline,
  });
}
