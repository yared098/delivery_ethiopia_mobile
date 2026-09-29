

class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.219.15.149:3000/api/v1',
  );

  // ══════════════════════════════════════════════════
  // CUSTOMER (existing)
  // ══════════════════════════════════════════════════

  // Auth
  static const String requestOtp = '/auth/customer/otp/request';
  static const String verifyOtp = '/auth/customer/otp/verify';
  static const String register = '/auth/customer/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  // Push / device tokens
  static const String deviceToken = '/auth/customer/device-token';
  static const String deviceTokenRemove = '/auth/customer/device-token/remove';

  // Profile
  static const String me = '/auth/customer/me';

  // Orders
  static const String orders = '/customer/orders';
  static String orderDetail(String id) => '/customer/orders/$id';

  // Public
  static String publicTrack(String token) => '/public/track/$token';

  // ══════════════════════════════════════════════════
  // COURIER (new)
  // ══════════════════════════════════════════════════

  // Auth
  static const String courierCheckPhone = '/auth/courier/check-phone';
  static const String courierRequestOtp = '/auth/courier/otp/request';
  static const String courierVerifyOtp = '/auth/courier/otp/verify';

  // Profile
  static const String courierMe = '/courier/me';
  static const String courierOnline = '/courier/me/online';
  static const String courierOffline = '/courier/me/offline';
  static const String courierLocation = '/courier/me/location';

  // Jobs
  static const String courierJobs = '/courier/jobs';
  static const String courierJobsStats = '/courier/jobs/stats';
  static String courierJobDetail(String id) => '/courier/jobs/$id';

  // Earnings
  static const String courierEarnings = '/courier/earnings';
  static const String courierEarningsSummary = '/courier/earnings/summary';

  // Courier device tokens
  static const String courierDeviceToken = '/auth/courier/device-token';
  static const String courierDeviceTokenRemove =
      '/auth/courier/device-token/remove';
}
