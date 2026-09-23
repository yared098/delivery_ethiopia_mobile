import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/device_token_service.dart';
import '../../../../core/notifications/push_service.dart';
import '../../../../di/service_locator.dart';
import '../../domain/usecases/get_me.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register_customer.dart';
import '../../domain/usecases/request_otp.dart';
import '../../domain/usecases/verify_otp.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.requestOtp,
    required this.verifyOtp,
    required this.registerCustomer,
    required this.getMe,
    required this.logout,
  }) : super(AuthInitial()) {
    on<RequestOtpEvent>(_onRequest);
    on<VerifyOtpEvent>(_onVerify);
    on<RegisterCustomerEvent>(_onRegister);
    on<RefreshMeEvent>(_onRefreshMe);
    on<LogoutEvent>(_onLogout);
    on<NoSessionEvent>((_, emit) => emit(AuthUnauthenticated()));
  }

  final RequestOtp requestOtp;
  final VerifyOtp verifyOtp;
  final RegisterCustomer registerCustomer;
  final GetMe getMe;
  final Logout logout;

  // ─────────────────────────────────────────────
  // REQUEST OTP
  // ─────────────────────────────────────────────
  Future<void> _onRequest(RequestOtpEvent e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await requestOtp(e.phone);
    res.fold(
      (l) => emit(AuthError(l.message)),
      (_) => emit(OtpSent(e.phone)),
    );
  }

  // ─────────────────────────────────────────────
  // VERIFY OTP
  // ─────────────────────────────────────────────
  Future<void> _onVerify(VerifyOtpEvent e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await verifyOtp(phone: e.phone, code: e.code);

    await res.fold(
      (l) async => emit(AuthError(l.message)),
      (r) async {
        if (r.isRegistrationRequired) {
          emit(RegistrationRequired(
            registrationToken: r.registrationToken!,
            phone: r.phone ?? e.phone,
          ));
        } else {
          emit(AuthAuthenticated(r.session!.account));
          await _uploadFcmToken();
        }
      },
    );
  }

  // ─────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────
  Future<void> _onRegister(
    RegisterCustomerEvent e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final res = await registerCustomer(
      registrationToken: e.registrationToken,
      name: e.name,
      email: e.email,
      defaultAddress: e.defaultAddress,
      defaultLat: e.defaultLat,
      defaultLng: e.defaultLng,
    );
    await res.fold(
      (l) async => emit(AuthError(l.message)),
      (session) async {
        emit(AuthAuthenticated(session.account));
        await _uploadFcmToken();
      },
    );
  }

  // ─────────────────────────────────────────────
  // REFRESH ME
  // ─────────────────────────────────────────────
  Future<void> _onRefreshMe(RefreshMeEvent e, Emitter<AuthState> emit) async {
    final res = await getMe();
    await res.fold(
      (l) async {
        if (l.statusCode == 401) {
          emit(AuthUnauthenticated());
        }
      },
      (account) async {
        emit(AuthAuthenticated(account));
        await _uploadFcmToken();
      },
    );
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────
  Future<void> _onLogout(LogoutEvent e, Emitter<AuthState> emit) async {
    // 1. Tell the server to detach this device from FCM.
    try {
      if (sl.isRegistered<PushService>() &&
          sl.isRegistered<DeviceTokenService>()) {
        final token = await sl<PushService>().getToken();
        if (token != null && token.isNotEmpty) {
          await sl<DeviceTokenService>().remove(token);
        }
      }
    } catch (err) {
      if (kDebugMode) debugPrint('🔔 server device-token remove failed: $err');
    }

    // 2. Invalidate the token locally.
    try {
      if (sl.isRegistered<PushService>()) {
        await sl<PushService>().deleteToken();
      }
    } catch (err) {
      if (kDebugMode) debugPrint('🔔 deleteToken on logout failed: $err');
    }

    // 3. Clear tokens + revoke refresh token.
    await logout();
    emit(AuthUnauthenticated());
  }

  // ─────────────────────────────────────────────
  // Helper
  // ─────────────────────────────────────────────
  Future<void> _uploadFcmToken() async {
    try {
      if (!sl.isRegistered<PushService>()) return;
      await sl<PushService>().refreshToken();
    } catch (e) {
      if (kDebugMode) debugPrint('🔔 refreshToken failed: $e');
    }
  }
}
