// 认证 Repository 抽象接口——Domain 层只依赖接口，不依赖 Dio 实现
abstract class AuthRepository {
  Future<void> loginWithPassword(String phone, String password);
  Future<void> loginWithSms(String phone, String code);
}
