import 'package:deliver_ethiopia/features/auth/domain/usecases/account_kind.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/device_token_service.dart';
import '../../../../core/notifications/push_service.dart';
import '../../../../core/storage/secure_storage.dart';
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

  bool _isLoggingOut = false;

  // ══════════════════════════════════════════════════
  // REQUEST OTP
  // ══════════════════════════════════════════════════
  Future<void> _onRequest(RequestOtpEvent e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await requestOtp(e.phone);
    res.fold(
      (l) => emit(AuthError(l.message)),
      (_) => emit(OtpSent(e.phone)),
    );
  }

  // ══════════════════════════════════════════════════
  // VERIFY OTP
  // ══════════════════════════════════════════════════
  Future<void> _onVerify(VerifyOtpEvent e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await verifyOtp(phone: e.phone, code: e.code);

    await res.fold(
      (l) async => emit(AuthError(l.message)),
      (r) async {
        // ── Courier login ──
        if (r.kind == AccountKind.courier) {
          if (sl.isRegistered<DeviceTokenService>()) {
            sl<DeviceTokenService>().setAccount(DeviceAccount.courier);
          }
          emit(AuthAuthenticated(r.session!.account, AccountKind.courier));
          await _uploadFcmToken();
          return;
        }

        // ── New customer → register ──
        if (r.isRegistrationRequired) {
          emit(RegistrationRequired(
            registrationToken: r.registrationToken!,
            phone: r.phone ?? e.phone,
          ));
          return;
        }

        // ── Existing customer → home ──
        if (sl.isRegistered<DeviceTokenService>()) {
          sl<DeviceTokenService>().setAccount(DeviceAccount.customer);
        }
        emit(AuthAuthenticated(r.session!.account, AccountKind.customer));
        await _uploadFcmToken();
      },
    );
  }

  // ══════════════════════════════════════════════════
  // REGISTER (customer)
  // ══════════════════════════════════════════════════
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
        if (sl.isRegistered<DeviceTokenService>()) {
          sl<DeviceTokenService>().setAccount(DeviceAccount.customer);
        }
        emit(AuthAuthenticated(session.account, AccountKind.customer));
        await _uploadFcmToken();
      },
    );
  }

  // ══════════════════════════════════════════════════
  // REFRESH ME — preserve stored kind  👈 FIXED
  // ══════════════════════════════════════════════════
  Future<void> _onRefreshMe(RefreshMeEvent e, Emitter<AuthState> emit) async {
    if (_isLoggingOut) return;

    // Which account is this device logged in as?
    AccountKind kind = AccountKind.customer;
    if (sl.isRegistered<SecureStorage>()) {
      kind =
          await sl<SecureStorage>().readAccountKind() ?? AccountKind.customer;
    }

    final res = await getMe(); // repository routes by kind internally

    await res.fold(
      (l) async {
        if (l.statusCode == 401 && !_isLoggingOut) {
          emit(AuthUnauthenticated());
        }
      },
      (account) async {
        if (sl.isRegistered<DeviceTokenService>()) {
          sl<DeviceTokenService>().setAccount(
            kind == AccountKind.courier
                ? DeviceAccount.courier
                : DeviceAccount.customer,
          );
        }
        emit(AuthAuthenticated(account, kind)); // 👈 preserve kind
        await _uploadFcmToken();
      },
    );
  }

  // ══════════════════════════════════════════════════
  // LOGOUT — RE-ENTRY GUARDED
  // ══════════════════════════════════════════════════
  Future<void> _onLogout(LogoutEvent e, Emitter<AuthState> emit) async {
    if (_isLoggingOut) {
      if (kDebugMode) debugPrint('🔔 logout already in progress — ignored');
      return;
    }
    _isLoggingOut = true;

    final push = sl.isRegistered<PushService>() ? sl<PushService>() : null;
    push?.setLoggingOut(true);

    try {
      if (push != null && sl.isRegistered<DeviceTokenService>()) {
        final token = await push.getToken();
        if (token != null && token.isNotEmpty) {
          await sl<DeviceTokenService>().remove(token);
        }
      }

      await logout(); // wipes SecureStorage (incl. account_kind)

      await push?.deleteToken();
    } catch (err) {
      if (kDebugMode) debugPrint('🔔 logout error: $err');
    } finally {
      emit(AuthUnauthenticated());
      push?.setLoggingOut(false);
      _isLoggingOut = false;
    }
  }

  // ══════════════════════════════════════════════════
  // Helper
  // ══════════════════════════════════════════════════
  Future<void> _uploadFcmToken() async {
    if (_isLoggingOut) return;
    try {
      if (!sl.isRegistered<PushService>()) return;
      await sl<PushService>().refreshToken();
    } catch (e) {
      if (kDebugMode) debugPrint('🔔 refreshToken failed: $e');
    }
  }
}
