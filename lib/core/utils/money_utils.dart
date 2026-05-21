import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

// 价格工具——禁止用 double 做金额运算（浮点精度问题）
// 所有价格传递用 Decimal 或 String，展示时调此工具格式化
class MoneyUtils {
  MoneyUtils._();

  static final _fmt = NumberFormat('#,##0.00', 'zh_CN');

  // Decimal → "¥1,234.56"
  static String format(Decimal amount) => '¥${_fmt.format(amount.toDouble())}';

  // 分（int）→ Decimal，用于后端以"分"为单位返回金额的场景
  // decimal 包的除法返回 Rational，用 toDecimal(scaleOnInfinitePrecision) 转回
  static Decimal fromFen(int fen) =>
      (Decimal.parse(fen.toString()) / Decimal.fromInt(100))
          .toDecimal(scaleOnInfinitePrecision: 2);

  // 字符串 → Decimal（安全解析，失败返回 0）
  static Decimal fromString(String s) {
    try {
      return Decimal.parse(s);
    } catch (_) {
      return Decimal.zero;
    }
  }

  // Decimal → 千分位字符串（不带货币符号，用于输入框回显）
  static String formatPlain(Decimal amount) => _fmt.format(amount.toDouble());
}
