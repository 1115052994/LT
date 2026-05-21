import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../constants/app_constants.dart';
import '../../flavor/flavor.dart';

// 拦截器链第 2 位：完整请求 / 响应日志
// - dev/test(verbose=true)：打印全量请求 + 响应 + 错误
// - pre(verbose=false)：只打错误
// - prod(enabled=false)：完全关闭（性能 + 隐私）
// - Authorization / Cookie 脱敏；Body 超阈值截断
class AppLoggerInterceptor extends Interceptor {
  static const _swKey = 'logger_stopwatch';

  // FlavorConfig 未初始化时 fallback 到 kDebugMode
  bool get _enabled => FlavorConfig.isLogEnabled;
  bool get _verbose => FlavorConfig.isLogVerbose;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_swKey] = Stopwatch()..start();

    if (_enabled && _verbose) {
      final reqId = options.hashCode.toRadixString(16);
      debugPrint('''
╔══ REQ #$reqId ══════════════════════════════
║ ${options.method}  ${options.uri}
║ Headers: ${_maskHeaders(options.headers)}
║ Body:    ${_prettyJson(options.data, max: AppConstants.logBodyMaxBytes)}
╚════════════════════════════════════════════''');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sw = response.requestOptions.extra[_swKey] as Stopwatch?;
    sw?.stop();

    if (_enabled && _verbose) {
      final reqId = response.requestOptions.hashCode.toRadixString(16);
      debugPrint('''
╔══ RES #$reqId  ${sw?.elapsedMilliseconds}ms ═══════════════
║ HTTP ${response.statusCode}  ${response.requestOptions.uri}
║ Body: ${_prettyJson(response.data, max: AppConstants.logRespMaxBytes)}
╚════════════════════════════════════════════''');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sw = err.requestOptions.extra[_swKey] as Stopwatch?;
    sw?.stop();

    if (_enabled) {
      final reqId = err.requestOptions.hashCode.toRadixString(16);
      debugPrint('''
╔══ ❌ ERR #$reqId  ${sw?.elapsedMilliseconds}ms ═══════════════
║ ${err.type}  ${err.requestOptions.uri}
║ HTTP ${err.response?.statusCode}
║ Message: ${err.message}
║ Body: ${_prettyJson(err.response?.data, max: AppConstants.logBodyMaxBytes)}
╚════════════════════════════════════════════''');
    }
    handler.next(err);
  }

  Map<String, dynamic> _maskHeaders(Map<String, dynamic> h) => {
        ...h,
        if (h.containsKey('Authorization'))
          'Authorization': _mask(h['Authorization'].toString()),
        if (h.containsKey('Cookie')) 'Cookie': '***',
      };

  String _mask(String s) =>
      s.length <= 12 ? '***' : '${s.substring(0, 6)}***${s.substring(s.length - 4)}';

  String _prettyJson(dynamic data, {required int max}) {
    if (data == null) return 'null';
    try {
      final str = const JsonEncoder.withIndent('  ').convert(data);
      return str.length > max
          ? '${str.substring(0, max)}\n  ...(截断，共 ${str.length} 字节)'
          : str;
    } catch (_) {
      final s = data.toString();
      return s.length > max ? '${s.substring(0, max)}...' : s;
    }
  }
}
