class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.172.127.149:3000/api/v1',
  );

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
}
