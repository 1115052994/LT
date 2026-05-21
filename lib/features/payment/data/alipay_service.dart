import 'package:flutter/foundation.dart';
import 'payment_gateway.dart';

/// 支付宝支付实现。
/// 依赖 tobias 包（支付宝官方 SDK 封装），当前为桩实现；
/// 接入步骤：
///   1. pubspec.yaml 添加 tobias: ^x.x.x
///   2. Android: AndroidManifest.xml 配置回调 Activity（见 PLAN.md §9）
///   3. iOS: Info.plist 配置 LSApplicationQueriesSchemes / CFBundleURLTypes
///   4. 将 _stubPay() 替换为 tobias.pay(orderString)
///
/// 注意：支付结果必须走后端验签，前端仅展示结果，禁止基于前端返回 code 直接确认发货。
class AlipayService implements PaymentGateway {
  const AlipayService();

  @override
  Future<PaymentResult> pay(String orderString) async {
    // TODO: 替换为真实 tobias SDK 调用
    // import 'package:tobias/tobias.dart';
    // final result = await aliPay(orderString);
    // return PaymentResult(code: result['resultStatus'] as String? ?? '6002');
    debugPrint('[AlipayService] stub pay called — orderString length: ${orderString.length}');
    return const PaymentResult(code: '6002', message: '支付宝 SDK 未接入');
  }
}
