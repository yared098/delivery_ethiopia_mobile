import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../core/network/dio_client.dart';
import '../core/storage/secure_storage.dart';

import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_me.dart';
import '../features/auth/domain/usecases/register_customer.dart';
import '../features/auth/domain/usecases/request_otp.dart';
import '../features/auth/domain/usecases/verify_otp.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

import '../features/profile/domain/usecases/update_profile.dart';

import '../features/orders/data/datasources/orders_remote_datasource.dart';
import '../features/orders/data/repositories/orders_repository_impl.dart';
import '../features/orders/domain/repositories/orders_repository.dart';
import '../features/orders/domain/usecases/create_order.dart';
import '../features/orders/domain/usecases/get_order_detail.dart';
import '../features/orders/domain/usecases/list_orders.dart';
import '../features/orders/presentation/bloc/create_order_bloc.dart';
import '../features/orders/presentation/bloc/orders_bloc.dart';

final sl = GetIt.instance;

Future<void> setupLocator({required Future<void> Function() onLogout}) async {
  if (sl.isRegistered<SecureStorage>()) return;

  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorage(const FlutterSecureStorage()),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(storage: sl<SecureStorage>(), onLogout: onLogout),
  );

  // ── Auth ──
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      storage: sl<SecureStorage>(),
    ),
  );
  sl.registerLazySingleton(() => RequestOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterCustomer(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetMe(sl<AuthRepository>()));
  sl.registerLazySingleton(
    () => AuthBloc(
      requestOtp: sl<RequestOtp>(),
      verifyOtp: sl<VerifyOtp>(),
      registerCustomer: sl<RegisterCustomer>(),
      getMe: sl<GetMe>(),
    ),
  );

  // ── Profile ──
  sl.registerLazySingleton(() => UpdateProfile(sl<AuthRepository>()));

  // ── Orders ──
  sl.registerLazySingleton<OrdersRemoteDataSource>(
    () => OrdersRemoteDataSource(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(sl<OrdersRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => CreateOrder(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => ListOrders(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => GetOrderDetail(sl<OrdersRepository>()));

  sl.registerFactory(
    () => OrdersBloc(
      listOrders: sl<ListOrders>(),
      getOrderDetail: sl<GetOrderDetail>(),
    ),
  );

  // 🔑 NEW: create-order bloc
  sl.registerFactory(
    () => CreateOrderBloc(createOrder: sl<CreateOrder>()),
  );
}
