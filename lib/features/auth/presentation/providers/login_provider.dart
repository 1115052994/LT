import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/app_providers.dart';

// 登录状态 AsyncNotifier——手写版，无需 build_runner
// state: AsyncData(null)=空闲  AsyncLoading=请求中  AsyncError=失败
class LoginNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> loginWithPassword(String phone, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).loginWithPassword(phone, password),
    );
  }

  Future<void> loginWithSms(String phone, String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).loginWithSms(phone, code),
    );
  }
}

final loginNotifierProvider =
    AsyncNotifierProvider<LoginNotifier, void>(LoginNotifier.new);
