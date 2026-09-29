import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/courier_model.dart';
import '../models/courier_job_model.dart';
import '../models/courier_earning_model.dart';

class CourierRemoteDataSource {
  final Dio _dio;
  CourierRemoteDataSource(this._dio);

  // ─── Profile ───
  Future<CourierModel> getMe() async {
    final res = await _dio.get(ApiConstants.courierMe);
    return CourierModel.fromJson(res.data);
  }

  Future<CourierModel> updateMe({
    String? name,
    String? email,
    String? vehiclePlate,
    String? vehicleModel,
    String? vehicleColor,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (vehiclePlate != null) data['vehiclePlate'] = vehiclePlate;
    if (vehicleModel != null) data['vehicleModel'] = vehicleModel;
    if (vehicleColor != null) data['vehicleColor'] = vehicleColor;

    final res = await _dio.patch(ApiConstants.courierMe, data: data);
    return CourierModel.fromJson(res.data);
  }

  // ─── Online / Location ───
  Future<void> goOnline({required double lat, required double lng}) async {
    await _dio.post(ApiConstants.courierOnline, data: {'lat': lat, 'lng': lng});
  }

  Future<void> goOffline() async {
    await _dio.post(ApiConstants.courierOffline);
  }

  Future<void> pushLocation({required double lat, required double lng}) async {
    await _dio
        .post(ApiConstants.courierLocation, data: {'lat': lat, 'lng': lng});
  }

  // ─── Jobs ───
  Future<List<CourierJobModel>> listJobs({String status = 'active'}) async {
    final res = await _dio.get(
      ApiConstants.courierJobs,
      queryParameters: {'status': status, 'limit': 50},
    );
    final raw = (res.data['data'] as List?) ?? [];
    return raw
        .map((e) => CourierJobModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CourierJobModel> getJob(String id) async {
    final res = await _dio.get(ApiConstants.courierJobDetail(id));
    return CourierJobModel.fromJson(res.data);
  }

  Future<Map<String, dynamic>> getJobsStats() async {
    final res = await _dio.get(ApiConstants.courierJobsStats);
    return res.data as Map<String, dynamic>;
  }

  // ─── Earnings ───
  Future<List<CourierEarningModel>> listEarnings({String? status}) async {
    final res = await _dio.get(
      ApiConstants.courierEarnings,
      queryParameters: {
        if (status != null) 'status': status,
        'limit': 50,
      },
    );
    final raw = (res.data['data'] as List?) ?? [];
    return raw
        .map((e) => CourierEarningModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getEarningsSummary() async {
    final res = await _dio.get(ApiConstants.courierEarningsSummary);
    return res.data as Map<String, dynamic>;
  }
}
