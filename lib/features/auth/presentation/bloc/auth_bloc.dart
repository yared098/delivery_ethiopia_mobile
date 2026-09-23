import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_me.dart';
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
  }) : super(AuthInitial()) {
    on<RequestOtpEvent>(_onRequest);
    on<VerifyOtpEvent>(_onVerify);
    on<RegisterCustomerEvent>(_onRegister);
    on<RefreshMeEvent>(_onRefreshMe);
    on<LogoutEvent>((_, emit) => emit(AuthUnauthenticated()));
  }

  final RequestOtp requestOtp;
  final VerifyOtp verifyOtp;
  final RegisterCustomer registerCustomer;
  final GetMe getMe;

  Future<void> _onRequest(RequestOtpEvent e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await requestOtp(e.phone);
    res.fold(
      (l) => emit(AuthError(l.message)),
      (_) => emit(OtpSent(e.phone)),
    );
  }

  Future<void> _onVerify(VerifyOtpEvent e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await verifyOtp(phone: e.phone, code: e.code);
    res.fold(
      (l) => emit(AuthError(l.message)),
      (r) {
        if (r.isRegistrationRequired) {
          emit(RegistrationRequired(
            registrationToken: r.registrationToken!,
            phone: r.phone ?? e.phone,
          ));
        } else {
          emit(AuthAuthenticated(r.session!.account));
        }
      },
    );
  }

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
    res.fold(
      (l) => emit(AuthError(l.message)),
      (session) => emit(AuthAuthenticated(session.account)),
    );
  }

  /// Silent refresh — do NOT emit AuthLoading (that would flash the login page).
  /// Only log out on a genuine 401 (dead session). Network errors keep us where we are.
  Future<void> _onRefreshMe(RefreshMeEvent e, Emitter<AuthState> emit) async {
    final res = await getMe();
    res.fold(
      (l) {
        // 401 → the interceptor already tried refresh and failed.
        // That's the only case where we're truly logged out.
        if (l.statusCode == 401) {
          emit(AuthUnauthenticated());
        }
        // Otherwise: silent fail, keep the current state
      },
      (account) => emit(AuthAuthenticated(account)),
    );
  }
}
