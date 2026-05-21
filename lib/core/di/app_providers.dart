import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/auth_service.dart';
import '../constants/app_constants.dart';
import '../flavor/flavor.dart';
import '../network/dio_client.dart';
import 'navigation_holder.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

export '../network/network_status.dart' show networkStatusProvider, NetworkStatus;

// ── 核心单例 Provider ───────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return DefaultAuthService(
    storage: const FlutterSecureStorage(),
    navigateTo: globalNavigate,
  );
});

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = FlavorConfig.baseUrlOrNull ?? AppConstants.baseUrl;
  return DioClient.create(
    baseUrl: baseUrl,
    authService: ref.watch(authServiceProvider),
  );
});

// ── 认证模块 Provider ───────────────────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(authRemoteDataSourceProvider),
    authService: ref.watch(authServiceProvider),
  );
});
