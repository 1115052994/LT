import 'package:dio/dio.dart';

// 统一解析后端响应外壳：{ "code": 0, "msg": "ok", "data": T }
// StatusInterceptor 已保证到达 Repository 时 code == 0
// 用法：
//   单对象：ApiResponse.of(resp).dataAs(Product.fromJson)
//   数组：  ApiResponse.of(resp).dataAsList(Product.fromJson)
//   分页：  ApiResponse.of(resp).dataAsPage(Product.fromJson)
class ApiResponse {
  final int code;
  final String msg;
  final dynamic data;

  const ApiResponse({required this.code, required this.msg, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
        code: (json['code'] as num?)?.toInt() ?? 0,
        msg: json['msg'] as String? ?? '',
        data: json['data'],
      );

  // 主入口：从 Dio Response 解析
  factory ApiResponse.of(Response<dynamic> response) =>
      ApiResponse.fromJson(response.data as Map<String, dynamic>);

  // data → 单个对象
  T dataAs<T>(T Function(Map<String, dynamic>) fromJson) =>
      fromJson(data as Map<String, dynamic>);

  // data → 对象列表（data 本身就是 JSON array）
  List<T> dataAsList<T>(T Function(Map<String, dynamic>) fromJson) =>
      (data as List<dynamic>)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();

  // data → 分页数据（data 是 { "items": [...], "total": N, "page": N, "pageSize": N }）
  PagedData<T> dataAsPage<T>(T Function(Map<String, dynamic>) fromJson) =>
      PagedData.fromJson(data as Map<String, dynamic>, fromJson);

  // data 为空或 null 时使用（如新增/删除接口只关心 code）
  bool get isSuccess => code == 0;
}

// 分页数据容器——对应后端分页外壳
// { "items": [...], "total": 100, "page": 1, "pageSize": 20 }
class PagedData<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  const PagedData({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PagedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawList =
        (json['items'] ?? json['list'] ?? const []) as List<dynamic>;
    return PagedData(
      items: rawList.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] ?? json['page_size'] as num?)?.toInt() ?? 20,
    );
  }

  bool get hasMore => items.length < total;
  bool get isEmpty => items.isEmpty;
  int get nextPage => page + 1;
}
