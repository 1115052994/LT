/// 统一支付抽象——本期只接入支付宝，未来加微信零成本替换。
abstract class PaymentGateway {
  /// 发起支付。[orderString] 由服务端返回的签名字符串。
  /// 返回支付结果 code（需回调后端验签，前端只展示）。
  Future<PaymentResult> pay(String orderString);
}

class PaymentResult {
  const PaymentResult({required this.code, this.message});

  final String code;
  final String? message;

  bool get isSuccess => code == '9000';
  bool get isProcessing => code == '8000' || code == '6004';
  bool get isCancelled => code == '6001';
  bool get isFailed => !isSuccess && !isProcessing && !isCancelled;
}
