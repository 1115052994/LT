# Flutter 电商 App 技术选型与架构方案

## Context

从零开发一个**中型多品类电商 App**，目标平台为 **iOS + Android**，后端**自建 REST/GraphQL**，**仅面向国内市场**。

**本期范围（确认）：**
- 支付：**仅接入支付宝**
- 列表页统一**预加载窗口 = 10 个**
- 网络层需要**统一拦截器**处理 HTTP 状态码（200 / 401 / 404 / 5xx 等）并友好提示
- 网络层需要**完整请求/响应日志拦截**（含耗时、Token 脱敏、大 Body 截断）
- UI 需要**统一空数据样式**组件（空列表、空搜索、空收藏、空订单、网络错误），插画由设计交付，默认统一样式，特殊页面可以单独更换
- 鉴权：**单 Token + 后端统一错误码识别过期**，无 refresh token，过期直接跳登录
- 必须做好：**刘海屏 / 异形屏适配、生命周期管理、内存防泄漏**
- **需要 App 内 H5（纯展示）**：活动页、协议页、帮助中心等。**H5 与原生不做业务交互**，不实现 JS Bridge
- **商品图片为普通 PNG 链接**，无 CDN 缩放参数 → 客户端强制做尺寸控制
- **环境**：开发(dev) / 测试(test) / 预发(pre) / 生产(prod) **四套 Flavor**，dev/test/pre 三套日常并行使用，可同一设备共存
- **权限收敛**：只申请 `INTERNET / ACCESS_NETWORK_STATE`；相机 / 相册 / 通知 / 位置等敏感权限不写入 manifest

工作目录 `D:\XM\Lt` 当前为空，全新项目。

---

## 一、整体架构

采用 **Clean Architecture（分层）+ Feature-first（按业务模块组织）**：

- **Presentation 层**：Page / Widget / 状态控制器
- **Domain 层**：Entity、UseCase、Repository 接口（纯 Dart）
- **Data 层**：Repository 实现、Remote/Local DataSource、DTO

### 推荐目录结构

```
lib/
├── main.dart
├── app.dart                      # MaterialApp + 路由 + 主题
├── core/
│   ├── network/
│   │   ├── dio_client.dart       # Dio 单例
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart       # token 注入 + 401 刷新
│   │   │   ├── status_interceptor.dart     # HTTP code 统一处理（200/404/5xx）
│   │   │   ├── logger_interceptor.dart
│   │   │   └── error_interceptor.dart      # DioException → 业务 Failure
│   │   └── api_response.dart     # 统一响应外壳 { code, msg, data }
│   ├── storage/                  # secure_storage / shared_prefs 封装
│   ├── router/                   # go_router 配置 + 登录守卫
│   ├── theme/                    # ThemeData、颜色、字号
│   ├── utils/                    # 工具函数、扩展
│   ├── errors/                   # Failure / Exception 定义
│   └── di/                       # get_it 注册
├── config/
│   ├── env.dart                  # dev / test / pre / prod 环境
│   └── constants.dart
├── features/
│   ├── auth/                     # 登录/注册（账号 + 短信）
│   ├── home/                     # 首页、推荐、轮播
│   ├── product/                  # 列表、详情、搜索
│   ├── category/                 # 分类、筛选
│   ├── cart/                     # 购物车
│   ├── order/                    # 下单、订单列表、详情、售后
│   ├── payment/
│   │   ├── alipay_service.dart   # 本期实现
│   │   └── payment_gateway.dart  # 统一抽象接口（暂只支付宝）
│   ├── address/                  # 收货地址
│   ├── coupon/                   # 优惠券
│   ├── user/                     # 个人中心
│   └── message/                  # 消息中心
├── shared/
│   ├── widgets/
│   │   ├── empty_state.dart      # 统一空数据组件（重点）
│   │   ├── error_state.dart
│   │   └── loading_state.dart
│   └── extensions/
└── l10n/                         # 中文为主，国际化预留
```

---

## 二、核心技术栈

### 1. 基础
| 类别 | 选型 |
|---|---|
| Flutter SDK | Stable 3.x（≥ 3.22），Dart 3.x |
| 静态分析 | `flutter_lints` |

### 2. 状态管理：**Riverpod 2.x**
- `flutter_riverpod` + `riverpod_generator`
- 编译时安全、依赖自动追踪、热重载友好、易测试
- 代码生成：`flutter pub run build_runner watch --delete-conflicting-outputs`
- 全局保活 Provider 用 `@Riverpod(keepAlive: true)` 注解；页面级用默认 `@riverpod`（自动 autoDispose）

### 3. 路由：**`go_router`**
- 官方推荐，支持深链接、嵌套路由、登录守卫

### 4. 网络层
- `dio`：HTTP 客户端
- `retrofit` + `retrofit_generator`：注解式 API
- `connectivity_plus`：网络状态
- `flutter_secure_storage`：Token 加密存储

### 5. 序列化
- `freezed` + `freezed_annotation`：不可变模型、`copyWith`、union types
- `json_serializable` + `json_annotation`
- 统一靠 `build_runner` 生成

### 6. 本地存储
| 用途 | 选型 |
|---|---|
| Token / 敏感信息 | `flutter_secure_storage` |
| 用户设置 / 轻量 KV | `shared_preferences` |

### 7. 依赖注入
- `get_it` + `injectable`（注解生成）

### 8. UI / 体验
| 用途 | 包 |
|---|---|
| 屏幕适配 | `flutter_screenutil` |
| 图片缓存 | `cached_network_image` |
| 轮播图 | `carousel_slider` + `smooth_page_indicator` |
| 瀑布流 | `flutter_staggered_grid_view` |
| 下拉刷新 / 上拉加载 | `easy_refresh` |
| 分页列表（含预加载） | `infinite_scroll_pagination` |
| Toast / Loading | `flutter_easyloading` |
| 图片预览（点击商品大图查看） | `photo_view` |
| 可见性检测 | `visibility_detector` |

### 9. 支付（本期：仅支付宝）
- **`tobias`**：支付宝官方 SDK 封装，唤起 → 回调 → 结果
- `PaymentGateway` 抽象接口 + `AlipayService` 实现，后续可平滑加渠道
- 平台配置：
  - iOS：`LSApplicationQueriesSchemes` 加 `alipay`、`alipays`、URL Types 配置回调 scheme
  - Android：`AndroidManifest` 配置回调 Activity
- 支付结果**必须走后端验签**，前端只展示

### 10. 工具
- `build_runner` / `flutter_gen_runner` / `flutter_launcher_icons` / `flutter_native_splash`
- `package_info_plus`：读取 App 版本号 / build 号（Debug Menu 展示用）

---

## 三、网络层拦截器与状态码处理（本期重点）

### 3.1 拦截器链（按顺序）

```
请求 → AuthInterceptor → LoggerInterceptor → 网络
响应 ← ErrorInterceptor ← StatusInterceptor ← LoggerInterceptor ← AuthInterceptor ← 网络
```

| 拦截器 | 职责 |
|---|---|
| `AuthInterceptor` | 自动注入 `Authorization: <token>` header；识别到后端**Token 过期错误码**则清 token + 跳登录页 |
| `LoggerInterceptor` | **打印完整请求 URL / Method / Headers / Body / 响应 code / 响应 Body / 耗时**（见 §3.4） |
| `StatusInterceptor` | **统一 HTTP 状态码处理 + 业务 code 处理**（见下） |
| `ErrorInterceptor` | `DioException` → 自定义 `Failure` 给上层 |

### 3.2 鉴权方式（**已确认**）

- 登录成功后端返回 `token`，**单 token，无 refresh token**
- 后续所有接口请求头携带 `Authorization: <token>`（或自定义 header，按后端约定）
- Token 过期时后端在响应体里返回**统一错误码**（例如 `code == 401001` 或类似，**需后端给出确定值**），此时：
  1. 清除本地 token
  2. 关闭所有受保护页面，跳到登录页
  3. 登录成功后回到原页面
- 不做静默刷新，过期就强制重新登录（实现简单，符合后端设计）

### 3.3 HTTP 状态码 + 业务 code 统一处理

后端约定响应外壳：
```json
{ "code": 0, "msg": "ok", "data": {...} }
```

| 条件 | 处理 |
|---|---|
| HTTP 200 + `code == 0` | 成功，把 `data` 透传 |
| HTTP 200 + **`code == <TOKEN_EXPIRED_CODE>`** | **Token 过期专用处理**：清 token → 跳登录页 → 不弹 toast |
| HTTP 200 + `code != 0`（其他业务错误） | Toast `msg`，抛 `BusinessFailure(code, msg)` |
| HTTP 401 | （兜底，正常应走业务 code）清 token、跳登录 |
| HTTP 403 | Toast "无权限访问" |
| HTTP 404 | Toast "请求的资源不存在" |
| HTTP 5xx | Toast "服务器开小差了，请稍后重试" |
| 超时 / 无网 | Toast "网络连接失败，请检查网络" |

> ⚠️ `TOKEN_EXPIRED_CODE` 需后端确认具体值；常见值 `40001` / `40101` / `401001` 等，**在 `constants.dart` 单点定义，禁止散落**。

### 3.4 请求 / 响应日志拦截（**本期重点**）

排查问题第一现场，必须做到"打开 IDE 控制台就能看到完整链路"。

#### 内容（每一条请求必须打印）
- 序号 / requestId（同一请求的 request 与 response 能对上）
- HTTP method + 完整 URL（含 query）
- 请求 Headers（脱敏 Token）
- 请求 Body（POST/PUT 完整 JSON，超过 10KB 截断）
- HTTP 状态码 + 业务 code + msg
- 响应 Body（完整 JSON 格式化打印，超过 50KB 截断）
- **耗时**（毫秒）
- 失败原因（DioExceptionType / 错误堆栈）

#### 实现要点

```dart
// lib/core/network/interceptors/logger_interceptor.dart
class AppLoggerInterceptor extends Interceptor {
  final _stopwatchKey = Object();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_stopwatchKey] = Stopwatch()..start();
    if (!_enabled) return handler.next(options);
    final reqId = options.hashCode.toRadixString(16);
    debugPrint('''
╔══ REQ #$reqId ══════════════════════════════
║ ${options.method}  ${options.uri}
║ Headers: ${_maskHeaders(options.headers)}
║ Body:    ${_prettyJson(options.data, max: 10240)}
╚════════════════════════════════════════════''');
    handler.next(options);
  }

  @override
  void onResponse(Response res, ResponseInterceptorHandler handler) {
    final sw = res.requestOptions.extra[_stopwatchKey] as Stopwatch?;
    sw?.stop();
    if (!_enabled) return handler.next(res);
    final reqId = res.requestOptions.hashCode.toRadixString(16);
    debugPrint('''
╔══ RES #$reqId  ${sw?.elapsedMilliseconds}ms ═══════════════
║ HTTP ${res.statusCode}  ${res.requestOptions.uri}
║ Body: ${_prettyJson(res.data, max: 51200)}
╚════════════════════════════════════════════''');
    handler.next(res);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sw = err.requestOptions.extra[_stopwatchKey] as Stopwatch?;
    sw?.stop();
    if (!_enabled) return handler.next(err);
    final reqId = err.requestOptions.hashCode.toRadixString(16);
    debugPrint('''
╔══ ❌ ERR #$reqId  ${sw?.elapsedMilliseconds}ms ═══════════════
║ ${err.type}  ${err.requestOptions.uri}
║ HTTP ${err.response?.statusCode}
║ Message: ${err.message}
║ Body: ${_prettyJson(err.response?.data, max: 10240)}
║ Stack: ${err.stackTrace}
╚════════════════════════════════════════════''');
    handler.next(err);
  }

  // 日志开关：dev/test 全开；pre 只打错误；prod 关
  bool get _enabled => FlavorConfig.current.flavor != Flavor.prod;

  // 脱敏：Authorization / Cookie 部分隐藏
  Map _maskHeaders(Map h) => {
    ...h,
    if (h.containsKey('Authorization')) 'Authorization': _mask(h['Authorization']),
    if (h.containsKey('Cookie')) 'Cookie': '***',
  };

  String _mask(String s) => s.length <= 12 ? '***' : '${s.substring(0, 6)}***${s.substring(s.length - 4)}';

  String _prettyJson(dynamic data, {required int max}) {
    if (data == null) return 'null';
    try {
      final str = const JsonEncoder.withIndent('  ').convert(data);
      return str.length > max ? '${str.substring(0, max)}\n  ...(truncated, ${str.length} bytes)' : str;
    } catch (_) {
      final s = data.toString();
      return s.length > max ? '${s.substring(0, max)}...' : s;
    }
  }
}
```

#### 关键规则
- **日志开关由 Flavor 控制**：dev/test 全开，pre 只打错误，prod 完全关闭（性能 + 隐私）
- **敏感字段脱敏**：`Authorization`、`Cookie`、密码、身份证、银行卡 在打印前掩码
- **大 Body 截断**：避免 IDE 控制台卡顿
- **错误级别**：成功用 `debugPrint`，失败用 `debugPrint` 标红前缀（仅控制台输出，不落本地文件）
- **耗时统计**：通过 `RequestOptions.extra` 挂 `Stopwatch`，便于发现慢接口
- **可视化美观**：用 box-drawing 字符画框，控制台一眼能扫

```dart
// lib/core/network/interceptors/status_interceptor.dart
class StatusInterceptor extends Interceptor {
  static const int tokenExpiredCode = 401001;  // ← 与后端确认后填入

  @override
  void onResponse(Response res, ResponseInterceptorHandler handler) {
    final code = res.statusCode ?? 0;
    if (code == 200) {
      final body = res.data as Map<String, dynamic>;
      final bizCode = body['code'] as int;

      // 1. 成功
      if (bizCode == 0) return handler.next(res);

      // 2. Token 过期：静默清 token + 跳登录，不弹 Toast
      if (bizCode == tokenExpiredCode) {
        getIt<AuthService>().handleTokenExpired();   // 清 token + 跳登录
        return handler.reject(DioException(
          requestOptions: res.requestOptions,
          error: const TokenExpiredFailure(),
        ));
      }

      // 3. 其他业务错误：Toast + 抛 BusinessFailure
      EasyLoading.showToast(body['msg'] ?? '操作失败');
      return handler.reject(DioException(
        requestOptions: res.requestOptions,
        error: BusinessFailure(bizCode, body['msg']),
      ));
    }
    handler.next(res);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final msg = switch (err.response?.statusCode) {
      401 => null,                       // 兜底，正常应走业务 code
      403 => '无权限访问',
      404 => '请求的资源不存在',
      >= 500 && < 600 => '服务器开小差了，请稍后重试',
      _ when err.type == DioExceptionType.connectionTimeout => '网络连接超时',
      _ when err.type == DioExceptionType.connectionError => '网络连接失败，请检查网络',
      _ => '请求失败',
    };
    if (err.response?.statusCode == 401) {
      getIt<AuthService>().handleTokenExpired();
    }
    if (msg != null) EasyLoading.showToast(msg);
    handler.next(err);
  }
}
```

提示方式统一走 `flutter_easyloading` 的 Toast，全局只一处定义文案，方便后期改为自定义弹窗。

---

## 四、空数据样式（统一组件）

电商页面到处是"没数据 / 没网络"的场景，必须一开始就统一，避免后期每个页面各画各的。

### 4.1 统一组件：`EmptyState`

```dart
// lib/shared/widgets/empty_state.dart
class EmptyState extends StatelessWidget {
  final String image;       // 插画路径，按场景切换
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    required this.image,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });
}
```

### 4.2 预设场景

插画由**设计同学统一交付**（已确认），开发先放占位灰度图，设计稿到位后批量替换。所有插画统一放在 `assets/empty/`，由 `flutter_gen` 生成类型安全引用（`Assets.empty.noProduct.image()`）。

| 场景 | 标题 | 资源名（待设计交付） |
|---|---|---|
| 空商品列表 | "暂无商品" | `assets/empty/no_product.png` |
| 空搜索结果 | "没有找到相关商品" | `assets/empty/no_search.png` |
| 空购物车 | "购物车空空如也，去逛逛吧" | `assets/empty/no_cart.png` |
| 空订单 | "暂无订单" | `assets/empty/no_order.png` |
| 空收藏 | "还没有收藏" | `assets/empty/no_favorite.png` |
| 空地址 | "暂无收货地址，去添加一个" | `assets/empty/no_address.png` |
| 空消息 | "暂无消息" | `assets/empty/no_message.png` |
| 网络错误 | "网络异常，点击重试" | `assets/empty/no_network.png` |

**设计交付要求**（向设计同事确认）：
- 尺寸：3 套（@1x / @2x / @3x）或 1 套 1080×1080 高清 PNG（带透明背景）
- 风格统一，与品牌色调一致
- 命名遵循上表 `no_xxx.png`

封装工厂方法：
```dart
EmptyState.products()
EmptyState.search()
EmptyState.cart(onGo: () => context.go('/home'))
EmptyState.network(onRetry: () => controller.refresh())
```

### 4.3 与列表配合

`infinite_scroll_pagination` 的 `PagedChildBuilderDelegate` 提供 4 个钩子，统一指向 `EmptyState` / `ErrorState` / Loading：

```dart
PagedChildBuilderDelegate<Product>(
  itemBuilder: ...,
  noItemsFoundIndicatorBuilder: (_) => EmptyState.products(),
  firstPageErrorIndicatorBuilder: (_) => EmptyState.network(onRetry: ...),
  firstPageProgressIndicatorBuilder: (_) => const Center(child: CircularProgressIndicator()),
  newPageProgressIndicatorBuilder: (_) => const Center(child: CircularProgressIndicator()),
);
```

---

## 五、列表性能 & 预加载策略（预加载窗口 = 10）

### 5.1 分页加载
```dart
_controller = PagingController(
  firstPageKey: 1,
  invisibleItemsThreshold: 10,   // 距底 10 个 item 触发下一页
);
```
后端约定每页 `pageSize = 20`。

### 5.2 图片预加载
对当前位置后 **10 个** item 主图调用 `precacheImage`，封装为 `PrecacheController.precacheNext(currentIndex, count: 10)`。

### 5.3 数据预取
列表项可见时（`visibility_detector`），对前方 10 个商品详情做低优先级预取并缓存至内存；快速划过用 `CancelToken` 取消。

### 5.4 性能基线
- `ListView.builder` + `addAutomaticKeepAlives: false`
- `cached_network_image` 指定 `memCacheWidth` 避免大图解码
- 列表项 `const` 构造，抽独立 `StatelessWidget`

---

## 六、刘海屏 / 异形屏适配

国内机型刘海、挖孔、灵动岛、水滴屏、曲面屏、底部手势条都要兼容，必须从模板就把规范立好。

### 6.1 统一 Scaffold 模板

封装 `AppScaffold` 强制走 `SafeArea`，业务页面禁止裸用 `Scaffold`：

```dart
// lib/shared/widgets/app_scaffold.dart
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar;  // 沉浸式时设 true
  final Color? statusBarBrightness;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,   // 默认深色图标
      child: Scaffold(
        appBar: appBar,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        body: SafeArea(
          top: appBar == null,            // 有 AppBar 时不重复避让
          bottom: true,                   // iOS Home Indicator 避让
          child: body,
        ),
      ),
    );
  }
}
```

### 6.2 屏幕适配（**强制规范**）

#### 6.2.1 适配基础
- **`flutter_screenutil`** 设计稿基准 `375 × 812`（iPhone X 系列，与设计师对齐）
- `main.dart`：
  ```dart
  ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,         // 文字最小尺寸自适应
    splitScreenMode: true,      // 折叠屏分屏适配
    builder: (_, __) => const App(),
  );
  ```

#### 6.2.2 单位强制规则

| 维度 | 单位 | 用法 | 示例 |
|---|---|---|---|
| 字体大小 | `.sp` | 所有 `fontSize` | `fontSize: 14.sp` |
| 宽 | `.w` | 所有 `width` / `horizontal padding` / `margin` | `width: 120.w`, `padding: EdgeInsets.symmetric(horizontal: 16.w)` |
| 高 | `.h` | 所有 `height` / `vertical padding` / `margin` | `height: 44.h` |
| 圆角 / 通用尺寸 | `.r` | `borderRadius`、`SizedBox` 占位 | `BorderRadius.circular(8.r)` |
| 屏宽 / 屏高百分比 | `.sw` / `.sh` | 整屏比例（如全屏弹窗宽度 80%） | `width: 0.8.sw` |

**强制规则（lint + code review 把关）**：
- ❌ 业务代码**禁止**出现任何裸 `fontSize: 14`、`width: 120`、`padding: EdgeInsets.all(16)`
- ✅ **必须**走 `.sp / .w / .h / .r`
- 唯一例外：`AppDivider` 等"必须 1 像素"的细线，用 `0.5` 不带单位（物理像素对齐）

#### 6.2.3 设计 Token 与 ScreenUtil 协同

`tokens.dart` 里只存"设计稿原始数值"，**使用时再加单位**：

```dart
// lib/core/theme/tokens.dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
class AppFontSize {
  static const caption = 10.0;
  static const small = 12.0;
  static const body = 14.0;
  static const subtitle = 16.0;
  static const title = 18.0;
  static const headline = 20.0;
}
class AppRadius {
  static const sm = 4.0;
  static const card = 8.0;
  static const lg = 12.0;
  static const button = 24.0;     // 胶囊
}

// 业务使用
Text('¥99', style: TextStyle(fontSize: AppFontSize.title.sp));
Padding(padding: EdgeInsets.all(AppSpacing.md.w), child: ...);
BorderRadius.circular(AppRadius.card.r);
```

#### 6.2.4 间距规范（设计师对齐）

电商常用间距阶梯：`4 / 8 / 12 / 16 / 20 / 24 / 32`，禁止出现 7、13、19 这种"中间值"，否则视觉会乱。

| 场景 | 推荐间距 |
|---|---|
| icon 与文字 | `AppSpacing.xs (4)` |
| 列表 item 内左右 padding | `AppSpacing.md (16)` |
| 列表 item 间距 | `AppSpacing.sm (8)` 或 `AppSpacing.md (16)` |
| 模块之间分组间距 | `AppSpacing.lg (24)` |
| 页面边缘 padding | `AppSpacing.md (16)` |
| 按钮内 padding | 上下 `AppSpacing.sm`、左右 `AppSpacing.lg` |

#### 6.2.5 字体规范

| 场景 | 字号 | 字重 |
|---|---|---|
| 大标题（页面顶部） | `headline (20)` | w700 |
| 中标题（卡片标题） | `title (18)` | w600 |
| 小标题 | `subtitle (16)` | w500 |
| 正文 | `body (14)` | w400 |
| 辅助文字 | `small (12)` | w400 |
| 备注 / 标签 | `caption (10)` | w400 |

行高建议 1.4 ~ 1.5，重要标题可 1.3。颜色走 `AppColors.textPrimary / textSecondary / textHint`。

#### 6.2.6 文字溢出与自适应

- 单行：`overflow: TextOverflow.ellipsis`、`maxLines: 1`
- 多行：`maxLines: 2 + ellipsis`
- 价格、SKU 等关键字段**禁止溢出**导致信息丢失：用 `Flexible` / `Expanded` 包裹，必要时缩字号（`FittedBox`）
- 中英文混排：`TextHeightBehavior(applyHeightToFirstAscent: false)` 避免顶部空白
- 数字字体推荐 monospace 风格（订单号、价格对齐美观）

#### 6.2.7 折叠屏 / 大屏适配

- 平板 / 折叠屏展开后宽度超过 600dp：考虑 `LayoutBuilder` 走双列布局
- `MediaQuery.of(context).size.shortestSide < 600` 判断手机模式

#### 6.2.8 关闭系统字体缩放干扰

为避免用户系统字体放大导致页面错乱，在 `MaterialApp` 包一层 `MediaQuery`：

```dart
MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: const TextScaler.linear(1.0),    // 锁定不跟随系统
    ),
    child: child!,
  ),
);
```

> 说明：本期不做适老化，所以锁死 1.0；后续若要支持，改为 `.clamp(0.85, 1.2)` 限制范围。

### 6.3 关键场景

| 场景 | 处理 |
|---|---|
| 首页轮播图 / banner | 顶部 banner 必须 `extendBodyBehindAppBar` + 透明 AppBar，避免刘海下空白；图片高度 = `(MediaQuery.padding.top + bannerHeight).h` |
| 商品详情底部购买栏 | 用 `SafeArea(top: false)` 包裹，避让底部手势条 |
| 全屏图片预览 | `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)`，退出时还原 |
| 键盘弹起 | `resizeToAvoidBottomInset: true`，用 `SingleChildScrollView` 包裹长表单 |
| 沉浸式状态栏 | `AnnotatedRegion<SystemUiOverlayStyle>` 按页面切换图标颜色 |

### 6.4 测试机型清单

至少覆盖：iPhone 14 Pro（灵动岛）、iPhone SE（无刘海）、华为 Mate 60（挖孔）、小米折叠屏、底部带物理键的旧 Android。

---

## 七、生命周期管理

### 7.1 App 级生命周期

监听 `AppLifecycleState`，在前后台切换时控制资源：

```dart
// lib/core/lifecycle/app_lifecycle_observer.dart
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // 恢复轮询、刷新 token
      case AppLifecycleState.inactive:
        // 短暂离开（来电、控制中心）
      case AppLifecycleState.paused:
        // 进入后台：停掉轮询；保存草稿
      case AppLifecycleState.detached:
        // 即将销毁：持久化必要数据
    }
  }
}
```

`main.dart` 注册：`WidgetsBinding.instance.addObserver(AppLifecycleObserver())`。

电商典型场景：
- 后台超过 N 分钟回到前台 → 刷新首页 / 校验 token
- 进入后台 → 停掉价格倒计时 Timer
- 切回前台 → 重新拉取购物车（防止多端不同步）

### 7.2 页面级生命周期

使用 `go_router` 的 `routerDelegate` 监听 + 自定义 `RouteAware`，或在 `StatefulWidget` 的 `initState/dispose` 处理：

- `initState`：初始化 Controller、订阅 Stream、注册监听
- `didChangeDependencies`：依赖变化时重新订阅
- `dispose`：**必须**释放 Controller、取消 Stream/Timer/CancelToken

### 7.3 Riverpod 生命周期

- **默认用 `autoDispose`**：页面离开自动释放，避免内存堆积
- 全局需要保活的（用户信息、购物车）：用普通 Provider，不加 `autoDispose`
- `ref.onDispose(() => ...)`：释放外部资源（Timer、Subscription、CancelToken）
- `ref.keepAlive()`：临时保活（如详情页返回列表后短期内再进去）

```dart
@riverpod
class ProductList extends _$ProductList {
  @override
  Future<List<Product>> build() async {
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);  // 离开页面取消请求
    return _repo.fetch(cancelToken: cancelToken);
  }
}
```

### 7.4 强制 dispose 检查清单

以下对象**必须**在 `dispose` 释放：

- `AnimationController` / `TabController` / `ScrollController` / `PageController` / `TextEditingController`
- `StreamSubscription` → `.cancel()`
- `Timer` → `.cancel()`
- `VideoPlayerController` / `ChewieController` → `.dispose()`
- `dio.CancelToken` → `.cancel()`
- 自定义 `ChangeNotifier` → `.dispose()`
- `FocusNode` → `.dispose()`
- `OverlayEntry` → `.remove()`

通过 `flutter_lints` 启用 `cancel_subscriptions`、`close_sinks` 规则做静态检查。

---

## 八、内存溢出防护

电商重灾区：商品大图 + 长列表 + WebView。

### 8.1 图片内存（后端只提供普通 PNG 链接，**客户端必须做尺寸控制**）

后端图片就是裸 PNG URL，没有 CDN 缩放参数，所以**全部压力压在客户端**，绝不能让原图直接进内存。

| 措施 | 配置 |
|---|---|
| 全局图片缓存上限 | `PaintingBinding.instance.imageCache.maximumSizeBytes = 60 * 1024 * 1024;`（无 CDN 缩略图，单图大，缓存上限调小） |
| 图片缓存数量 | `imageCache.maximumSize = 80;` |
| **列表小图** | `CachedNetworkImage(memCacheWidth: 400)` — 列表 item 宽 ≤ 200dp，按 2x dpr 解码到 400px 即可 |
| **详情大图** | `CachedNetworkImage(memCacheWidth: 1080)` — 不超过屏幕物理像素 |
| **轮播 banner** | `memCacheWidth: 1080`，`fadeInDuration: 0`（避免快速切换的解码风暴） |
| 头像 | `memCacheWidth: 200` |
| 占位 / 错误图 | `placeholder` 用 `CircularProgressIndicator`，`errorWidget` 用本地兜底图 |
| 退出长列表页 | `imageCache.clear()` 主动清理（或在内存压力回调时） |

封装统一的 `AppNetworkImage`，强制传 `memCacheWidth`：

```dart
// lib/shared/widgets/app_network_image.dart
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;

  // 自动按 width 推算解码尺寸，避免每个调用方各传各的
  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (width * dpr).round().clamp(100, 1080);
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) => const _ErrorImage(),
      fadeInDuration: const Duration(milliseconds: 100),
    );
  }
}
```

**约定：业务层禁止直接用 `CachedNetworkImage` / `Image.network`，统一走 `AppNetworkImage`。** 通过 lint 自定义规则或 code review 把关。

### 8.2 长列表内存

- 强制 `ListView.builder` / `GridView.builder`，禁止一次性 `children: [...]`
- `addAutomaticKeepAlives: false`、`addRepaintBoundaries: true`
- 复杂 item 用 `RepaintBoundary` 包裹避免重绘整列
- 滚动到看不见的范围后内存自动回收（Flutter 默认）

### 8.3 内存压力响应

监听系统低内存事件主动释放：

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
```

### 8.4 防泄漏工具链

- **DevTools → Memory tab**：定期看堆增长曲线，重点关注离开页面后内存是否回落
- **`leak_tracker`**（Flutter 内置）：debug 模式自动检测未释放对象
- 在 `main.dart` 开发环境开：`LeakTracking.start();`
- 每个 PR 必须跑一次"进入页面 → 离开页面 → 重复 10 次"看内存是否泄漏

### 8.5 后端配合

- 本期图片为普通 PNG 链接，无 CDN 缩放参数；后续若迁 CDN，`AppNetworkImage` 内部留好替换 URL 参数的钩子
- 列表接口避免一次返回全字段（详情字段独立接口）

---

## 九、App 内 H5（**纯展示**）

H5 用于活动页、协议页、帮助中心、隐私政策等**纯静态展示**场景（运营可改、不发版）。**本期 H5 与原生之间不做任何业务交互**——不调商品、购物车、支付，也不需要 JS Bridge。

### 9.1 技术选型：**`flutter_inappwebview`**

虽然纯展示用 `webview_flutter` 也够，但选 `flutter_inappwebview` 是为了：
- 更好的 Cookie 管理（协议页可能需要带登录态）
- 加载状态/进度条回调更完善
- 后期如需扩展能力时不用换库

### 9.2 统一 `AppWebView` 组件

封装在 `lib/shared/widgets/app_webview.dart`，业务层禁止裸用 `InAppWebView`：

```dart
class AppWebView extends StatefulWidget {
  final String url;
  final String? title;             // null 则用 H5 document.title
  final bool showProgressBar;
  final bool pullToRefresh;
}
```

内置能力：
- AppBar 标题跟随 H5 `document.title` 或外部传入
- 顶部进度条（`onProgressChanged`）
- 加载失败显示 `EmptyState.network(onRetry: reload)`
- 下拉刷新
- 返回键：H5 有历史栈先 `goBack()`，没有再关闭 WebView
- 长按图片可保存（基础能力，可选）

### 9.3 与原生交互边界（**本期最小化**）

- **不实现 JS Bridge**：不暴露 `addJavaScriptHandler`
- **不允许 H5 调用原生支付 / 加购 / 跳商详**
- 仅做**单向**最小配合：
  - 拦截 H5 链接点击：H5 内的 `<a href>` 如果指向自家 App 协议页或外部链接，按规则处理（外部走 `url_launcher`）
  - 拦截 H5 触发的 `tel:` / `mailto:`（系统打开）
  - 协议页可能需要 Cookie 带 token —— 通过 `CookieManager` 在加载前注入（单向 native → H5，不反向）

> 后期如确需 H5 ↔ 原生交互（例如活动落地页跳商详），再启用 JS Bridge，预留扩展位但**本期不写任何 handler**。

### 9.4 性能与内存

- **WebView 是大内存对象**，一个实例 50~150MB
- 进入 H5 → 离开 → **必须 dispose**（`AppWebView` 在 `dispose` 内调 `controller.dispose()`）
- 同一时间限制 ≤ 1 个 WebView 活跃
- iOS 14+ 用 `WKWebView`（默认）；Android 用系统 WebView，不打包额外内核

### 9.5 安全

- 白名单域：只允许加载已知域名，外部链接用 `url_launcher` 系统浏览器打开
- 禁用 `allowsLinkPreview`
- HTTPS 强制；Android `mixedContentMode: MIXED_CONTENT_NEVER_ALLOW`
- 文件协议禁用：`allowFileAccess: false`
- 不开 inspectable（release）

### 9.6 路由整合

`go_router` 注册通用路由：

```dart
GoRoute(
  path: '/webview',
  builder: (_, state) => AppWebView(
    url: state.uri.queryParameters['url']!,
    title: state.uri.queryParameters['title'],
  ),
);
```

业务调用：`context.push('/webview?url=${Uri.encodeComponent(url)}&title=活动')`。

---

## 十、容易遗漏的关键事项（系统补齐）

电商上线前的"隐形必做"清单，分类汇总。

---

### A. 合规与安全（**国内必做，不做无法上架**）

#### A.1 隐私政策与首次启动合规
- 首次启动**必须**弹出《用户协议》《隐私政策》同意框，**同意前禁止初始化任何 SDK**（支付宝、设备信息、第三方统计等）
- 隐私政策需明确：收集的信息类型、用途、保存期限、第三方 SDK 列表、用户权利
- 二次确认机制：用户点不同意 → 二次弹窗解释 → 仍不同意则退出 App
- iOS 17+：必须提供 `PrivacyInfo.xcprivacy`（隐私清单）
- 工信部检查项：禁止"频繁自启动"、禁止"超范围收集"、提供"撤回同意"入口

#### A.2 权限合规（场景化申请，而非启动即申请）

本期需要的权限**已大幅收敛**——相机/相册/通知/位置均不申请。仅以下两类必须：

| 权限 | 场景 | 说明文案要求 |
|---|---|---|
| 存储 | 缓存商品图片 | "用于缓存商品图片，减少流量消耗" |
| 设备信息 | OAID 标识（用户同意隐私后） | "用于个性化推荐和反作弊" |

封装 `PermissionService` 走 `permission_handler`，**所有申请前先弹自定义解释弹窗**，再调系统弹窗（合规要求）。

> 相机 / 相册 / 通知 / 位置 在本期**不申请、不调用、不写入 manifest**——这些权限的存在性会被工信部 / 应用市场审核扫描，留着没用会被打回。

#### A.3 设备唯一标识（**禁止用 IMEI / IDFA**）
- Android：用 **OAID**（移动安全联盟标识），包 `oaid_flutter`
- iOS：用 **IDFV**（`device_info_plus`）
- 不可用 MAC、IMEI、Android ID、序列号（工信部禁止）
- 标识获取**必须在用户同意隐私政策后**

#### A.4 HTTPS / 网络安全
- 全站 HTTPS，禁用明文 HTTP
- Android `network_security_config.xml`：release 不允许明文；debug 允许（便于抓包）
- 敏感接口考虑 **SSL Pinning**（dio_certificate_pinning）—— 防中间人，权衡升级成本
- 密码字段前端 **RSA 加密**后传输（后端给公钥）

#### A.5 数据安全
- Token / 用户信息 → `flutter_secure_storage`
- 不要把敏感字段（手机号、身份证）打到日志里
- 日志脱敏：手机号 `138****8888`、身份证 `110***********1234`

---

### B. 全局机制

#### B.1 全局异常兜底（**核心稳定性**）
```dart
// main.dart
void main() {
  runZonedGuarded(() {
    FlutterError.onError = (details) {
      debugPrint('Flutter error: ${details.exception}\n${details.stack}');
    };
    PlatformDispatcher.instance.onError = (e, st) {
      debugPrint('Platform error: $e\n$st');
      return true;
    };
    runApp(const MyApp());
  }, (e, st) => debugPrint('Zone error: $e\n$st'));
}
```
**异常必须捕获**，避免单点崩溃白屏。本期仅输出到控制台，不落本地文件。

#### B.2 登录守卫
- `go_router` 的 `redirect` 钩子：未登录访问需登录页面 → 跳登录 → 登录成功后**返回原页面**（保存 `from` 参数）
- 状态变化（登录/登出）自动触发路由刷新（`refreshListenable`）

#### B.3 防重复提交 / 节流防抖
- **下单按钮**：点击后立即 disabled，请求返回前不可再点
- 通用 `throttle` / `debounce` 扩展：
  - 搜索建议输入：`debounce(300ms)`
  - 加购按钮、点赞、收藏：`throttle(500ms)`
- 封装 `AppButton` 内置防抖，业务统一用，不裸用 `ElevatedButton`

#### B.4 全局 Loading 策略
- **页面级**：居中 `CircularProgressIndicator`
- **按钮级**：按钮内 spinner
- **全屏遮罩**：仅用于支付等关键操作（`EasyLoading.show`）
- 严禁所有请求都用全屏遮罩

#### B.5 网络请求重试
- `dio_smart_retry`：对 GET、幂等接口自动重试 3 次（指数退避）
- POST / 下单等**非幂等接口禁止自动重试**（防止重复下单）

---

### C. 电商业务关键能力

#### C.1 金额 / 价格精度（**用 Decimal，禁用 double 计算**）
```yaml
decimal: ^3.2.1
intl: ^0.19.0
```
- 价格存储用 `String` 或 `Decimal`，**绝不用 `double`**（浮点累加丢精度）
- 展示用 `NumberFormat.currency(locale: 'zh_CN', symbol: '¥')`
- 千分位：`NumberFormat('#,##0.00', 'zh_CN').format(price)`
- 封装 `Money` 值对象，所有加减乘除走它

#### C.2 倒计时统一管理
电商有大量倒计时：订单支付（5 分钟）、验证码（60s）。
- 封装 `CountdownController`，**单一 Timer 驱动多个倒计时**（避免每个组件起 Timer 内存爆炸）
- 后台时 Timer 停（生命周期联动），回前台用 wall clock 补算剩余时间

#### C.3 SKU 选择器
- 多规格组合（颜色 × 尺寸 × 套餐）的可选/不可选/缺货状态判定
- 算法：邻接矩阵剪枝；社区有 `flutter_sku_selector` 可参考
- 选择规格后实时刷新价格、库存、主图

#### C.4 地址选择
- 三级联动（省/市/区）+ 街道：`flutter_picker` 或 `city_pickers`
- 数据源：本地 JSON（民政部 6 位行政区划码，2~3MB）
- 地址识别：粘贴整段文字（"张三 138xxxx 北京市朝阳区..."）→ 后端解析或本地正则
- 不做自动定位（位置权限本期不申请）

#### C.5 富文本 / 商详
- 商品详情若含富文本字段：`flutter_html`
- 大段 HTML 注意懒加载图片、解决图片闪烁
- 或直接走 H5 商详（用上面的 `AppWebView`）

#### C.6 搜索历史
- 本地存储最近 10 条搜索词：`shared_preferences` 存 JSON 数组，LIFO 顺序
- 热搜词：接口拉取，缓存至内存（页面关闭即失效，不持久化）
- 提供"清空搜索历史"入口（合规要求）
- 搜索历史展示在输入框获焦时展开，失焦收起

---

### D. 工程化

#### D.1 环境切换 / Debug Menu
- 四套配置：`dev` / `test` / `pre` / `prod` → `--dart-define=ENV=dev`
- Debug 模式提供"开发者面板"：切换环境、清缓存、查看日志、模拟弱网、Token 复制
- 显示 build 号 + commit hash 便于排查（通过 `package_info_plus` 读取）

#### D.2 代码质量自动化
- `flutter analyze`：每次提交前在 CI 运行，0 warning 才通过
- `flutter format`：统一代码格式，禁止手动排版冲突
- `husky` + pre-commit hook：提交时自动触发 `flutter format` + `flutter analyze`
- 目标：主干分支无 lint error，PR 合并前必须 analyze 通过

#### D.3 包体积
- `flutter build apk --split-per-abi`：arm64-v8a / armeabi-v7a 分包
- 资源压缩：TinyPNG 处理 png
- 字体：只保留中文常用字、按需子集化（`fonttools`）
- 大资源走 CDN，不打进包
- 目标：单 ABI < 25MB

#### D.4 混淆（Android）
- `flutter build apk --obfuscate --split-debug-info=./symbols/`
- `proguard-rules.pro`：保留支付宝 SDK、JSON 反射类
- 符号文件保留好，崩溃栈可还原

#### D.5 多渠道打包（如需上架多个市场）
- 安卓：华为、应用宝、小米、OPPO、vivo、应用商店 — `walle` 工具单包多渠道（Tencent 出品）
- iOS：单渠道 App Store
- 渠道号通过 manifest meta-data 或 walle 注入，用于埋点

#### D.6 应用市场合规
- 各市场对隐私政策、SDK 清单要求略有差异
- 华为：需提供 GMS 移除版（仅用 HMS）—— 本期不涉及
- 苹果 App Store：内购规则、外部支付禁止用 IAP 流程

---

### E. 启动流程

#### E.1 冷启动闪屏 (Splash)
- `flutter_native_splash`：原生闪屏，避免白屏过渡
- 进入 Flutter 后的 `SplashPage`：
  1. 加载主题、读取 Token
  2. 检查 App 更新
  3. 检查隐私协议状态
  4. Token 有效 → 跳首页；无效 → 跳登录页
- 总时长目标 < 1.5s（中端机）

#### E.2 App 更新检查
- 启动时拉版本号接口
- 强更：必须升级，关闭按钮置灰
- 普更：可跳过本次，记录"今日已提示"
- Android：用插件flutter_app_updater；或跳应用市场
- iOS：跳 App Store

#### E.3 首页预热
- Splash 阶段预拉首页接口，进入首页瞬间渲染
- 首屏数据 + 兜底（无网时显示 `EmptyState.network` 提示用户重试）

---

### F. iOS / Android 平台差异

| 项 | iOS | Android |
|---|---|---|
| 路由转场 | `CupertinoPageRoute`（右滑返回） | `MaterialPageRoute` |
| 状态栏 | `AnnotatedRegion` 即可 | 还需 `SystemChrome.setSystemUIOverlayStyle` |
| 返回手势 | 系统右滑 | 物理/虚拟返回键 → `PopScope` 拦截 |
| 字体 | 苹方（系统） | 思源黑体 / Roboto |
| 沉浸式 | 默认 | 需显式设置 |
| 振动 | 轻触反馈 `HapticFeedback.lightImpact` | 同 API |
| 后台运行 | 受限严格 | 相对宽松 |

封装 `PlatformAware` 工具，避免业务层散写 `Platform.isIOS`。

**Android 双击返回退出 App 实现**（底部 Tab 主页使用）：

```dart
// lib/shared/widgets/double_back_exit_wrapper.dart
class DoubleBackExitWrapper extends StatefulWidget {
  final Widget child;
  const DoubleBackExitWrapper({required this.child});
  ...
}

class _DoubleBackExitWrapperState extends State<DoubleBackExitWrapper> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          EasyLoading.showToast('再按一次退出');
          return;
        }
        SystemNavigator.pop();
      },
      child: widget.child,
    );
  }
}
```

---

### G. 业务防御性细节

- **下单链接幂等**：前端生成 `clientOrderId` 跟随请求，后端去重，**网络重试不会重复下单**
- **价格二次校验**：下单时前端展示价格只是参考，**最终以提交后端返回价格为准**（防止本地缓存价、活动失效价）
- **库存校验**：加购、下单都需后端实时校验，前端展示库存仅参考
- **优惠券失效**：进入结算页前重新校验优惠券有效性，避免下单接口报错
- **未读消息红点**：本地按消息中心未读数计算，避免每页轮询
- **购物车多端同步**：登录后立即拉取服务端购物车，与本地合并（本地有但服务端没有的 → 推送上去）

---

## 十一、深度补充（Flutter 工程化全景）

前面是"业务必做项"，这里是 Flutter **工程化**与**进阶能力**清单，少做不会立刻挂，但少做就是隐患。

---

### H. 数据层与异步状态范式

#### H.1 AsyncValue（Riverpod 标配）
Riverpod 的 `AsyncValue<T>` 天然代表三态 `data / loading / error`，**禁止在业务层手写 `bool isLoading + Error? error + T? data` 这种三个字段**：

```dart
@riverpod
Future<List<Product>> products(ProductsRef ref) async => ref.read(repoProvider).fetch();

// UI 层
final state = ref.watch(productsProvider);
return state.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => EmptyState.network(onRetry: () => ref.invalidate(productsProvider)),
  data: (list) => ProductGrid(items: list),
);
```

#### H.2 Result / Either 错误模式
Data 层返回 `Result<Success, Failure>`（用 `fpdart` 或自定义 sealed class），让 Domain 层显式处理失败：
```dart
sealed class Result<T> {}
class Ok<T> extends Result<T> { final T value; ... }
class Err<T> extends Result<T> { final Failure failure; ... }
```
拒绝裸 `try-catch` 在 UI 层。

#### H.3 Repository 数据策略
- 数据不做本地持久化缓存；页面离开时 Provider autoDispose，重进重取
- 主动 invalidate：下单后调 `ref.invalidate(cartProvider)`，购物车立即重取

---

### I. 路由与深链

#### I.1 路由状态恢复
- 滚动位置：`PageStorageKey` + `ScrollController`
- Tab 状态：`AutomaticKeepAliveClientMixin`
- 表单草稿：`shared_preferences` 临时保存 + 离开页面前 `PopScope` 提示

#### I.2 转场基础
- iOS 默认右滑返回（`CupertinoPageRoute`）
- Android 物理返回键拦截（`PopScope`）

---

### J. 多 Flavor / 环境切换（**本期重点：4 套环境共存**）

支持 **开发(dev) / 测试(test) / 预发(pre) / 生产(prod)** 四套完全独立的构建，可在同一设备共存。日常以 dev / test / pre 三套为主，prod 用于正式打包上架。

| 维度 | dev（开发） | test（测试） | pre（预发） | prod（生产） |
|---|---|---|---|---|
| Bundle ID | `com.x.shop.dev` | `com.x.shop.test` | `com.x.shop.pre` | `com.x.shop` |
| App 名称 | "Shop Dev" | "Shop Test" | "Shop Pre" | "Shop" |
| 图标 | 红色 DEV 角标 | 黄色 TEST 角标 | 蓝色 PRE 角标 | 正式 |
| baseUrl | dev API | test API | pre API | prod API |
| 日志级别 | verbose（全开） | debug（全开） | info（错误） | warn（关闭） |
| 抓包代理 | 允许 | 允许 | 禁止 | 禁止 |
| 支付宝 | 沙箱 | 沙箱 | 正式（小额） | 正式 |

实现：
- 环境配置文件：`env/dev.json` / `env/test.json` / `env/pre.json` / `env/prod.json`，存 `BASE_URL`、`LOG_LEVEL`、`ALIPAY_APP_ID` 等
- 启动注入：`flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json`
- iOS：Xcode 配置 4 个 Scheme + 4 份 xcconfig
- Android：`build.gradle` 中 `productFlavors { dev { ... } test { ... } pre { ... } prod { ... } }`
- 四个 entry：`main_dev.dart` / `main_test.dart` / `main_pre.dart` / `main_prod.dart`，统一 `→ bootstrap(Flavor.X)`
- 统一入口：`lib/core/flavor/bootstrap.dart` 接收 `Flavor` 枚举，初始化对应配置

```dart
// lib/core/flavor/flavor.dart
enum Flavor { dev, test, pre, prod }

class FlavorConfig {
  final Flavor flavor;
  final String baseUrl;
  final String alipayAppId;
  final LogLevel logLevel;
  final bool allowProxy;

  static late FlavorConfig current;
  static bool get isProd => current.flavor == Flavor.prod;
  static bool get isPre => current.flavor == Flavor.pre;
  static bool get isDevOrTest => current.flavor == Flavor.dev || current.flavor == Flavor.test;
}
```

**Debug Menu（仅 dev / test 显示）**：
- App 内提供"环境信息"面板：当前 Flavor、baseUrl、build 号、commit hash
- 不允许运行时切换 Flavor（必须重打包），避免内存中数据污染
- 但可以**在同一 Flavor 内切换 baseUrl**（如果 dev 有多套联调地址）

---

### K. 原生侧关键配置

#### K.1 iOS（`ios/Runner/Info.plist`）
- `NSAppTransportSecurity`：默认禁明文，例外域名加白
- 本期**不申请**相机/相册/位置/通知权限，对应 `NSCameraUsageDescription` 等 key **不要加进 Info.plist**（加了等于声明使用，审核会查实际调用）
- `LSApplicationQueriesSchemes`：加 `alipay`、`alipays`、`weixin`、`mqq`、`tel`、`sms`、`mailto`
- `CFBundleURLTypes`：注册支付宝、微信回调 scheme
- `UIBackgroundModes`：本期不开启（无后台定位/音频/下载需求）
- `ITSAppUsesNonExemptEncryption=false`：避免 App Store Connect 反复询问加密合规

#### K.2 Android（`android/app/src/main/AndroidManifest.xml`）
- `application` 节点：`usesCleartextTraffic="false"`（release）+ `networkSecurityConfig`
- 权限：仅 `INTERNET / ACCESS_NETWORK_STATE`（**不申请 CAMERA / READ_MEDIA_IMAGES / POST_NOTIFICATIONS / ACCESS_FINE_LOCATION**，本期均不使用）
- `queries`：API 30+ 必须显式声明可查询的第三方包名（微信、支付宝、浏览器、邮件）
- `provider`：FileProvider，用于下载 APK 安装
- `MainActivity`：`android:exported="true"`、`launchMode="singleTop"`
- `dataBinding`、`viewBinding` 不需要
- **Android 14+ 预测性返回手势**：在 `<application>` 节点加 `android:enableOnBackInvokedCallback="true"`，并确保 `PopScope` 替代已废弃的 `WillPopScope`

#### K.3 签名管理
- iOS：Apple Developer 自动签名 + Provisioning Profile
- Android：keystore 文件**不进 Git**，CI 用环境变量注入；`key.properties` 写入 `.gitignore`

---

### L. 表单 / 输入

#### L.1 表单库
- `flutter_form_builder` + `form_builder_validators`：表单状态管理 + 内置常用校验
- 优于裸 `Form` + `TextEditingController`，省 70% 样板

#### L.2 输入限制
- 手机号：`inputFormatters: [LengthLimitingTextInputFormatter(11), FilteringTextInputFormatter.digitsOnly]`
- 金额：自定义 `MoneyInputFormatter`（最多两位小数）
- 验证码：`pin_code_fields`

#### L.3 国内特化校验
- 手机号：`^1[3-9]\d{9}$`
- 身份证：18 位 + 校验位算法
- 银行卡：Luhn 算法
- 中文姓名：`^[一-龥·]{2,15}$`

#### L.4 键盘与输入体验
- `TextInputType.phone` / `.emailAddress` / `.numberWithOptions(decimal: true)`
- `textInputAction: TextInputAction.next` → 下一个输入框
- `autofillHints: [AutofillHints.password]` → 系统密码自动填充
- 焦点切换：`FocusNode` + `FocusScope.of(context).nextFocus()`

---

### M. 设计 Token（与 §6.2 适配规则配套）

间距 / 字号 / 圆角 token 已在 §6.2.3 ~ 6.2.5 详述。此处仅强调颜色 token：

```dart
// lib/core/theme/tokens.dart - 颜色部分
class AppColors {
  // 品牌
  static const primary = Color(0xFFFF6600);
  static const primaryLight = Color(0xFFFFE5D6);

  // 文字
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textHint = Color(0xFF999999);
  static const textDisabled = Color(0xFFCCCCCC);

  // 功能
  static const danger = Color(0xFFE53935);     // 价格红、删除、错误
  static const success = Color(0xFF52C41A);
  static const warning = Color(0xFFFAAD14);

  // 背景 / 分割
  static const background = Color(0xFFF5F5F5);
  static const cardBg = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE5E5E5);
}
```

**强制规则**：业务代码**禁止**出现 `Color(0xFF...)` 硬编码，全部走 `AppColors.*`。lint 把关。

---

### N. 合规细项（国内 App 必备）

#### N.1 账号注销
- 个人信息保护法 + 工信部要求：必须提供"注销账号"入口
- 流程：二次确认 → 后端异步处理 → 注销期内可撤销
- 注销后清空本地所有数据

#### N.2 个人信息导出 / 第三方共享清单
- "我的 → 设置 → 个人信息收集清单"
- 列出所有第三方 SDK 收集的信息（即使未来加的，先留入口）

---

### O. 工程协作

#### O.1 Git 工作流
- 分支：`main`（受保护） + `develop` + `feature/*` + `hotfix/*`，或 trunk-based
- Commit 规范：Conventional Commits（`feat: ...` / `fix: ...` / `chore: ...`）
- 工具：`commitlint` + `husky`（pre-commit 自动跑 `flutter format` / `flutter analyze`）

#### O.2 PR 模板 / Code Review
- 模板：变更说明 / 测试范围 / 截图 / 影响面
- Review 关注点：状态泄漏、控制器是否 dispose、网络异常分支、空态、性能

#### O.3 Monorepo / 包管理
- 项目规模上来后用 `melos` 拆 packages（`core/` / `features/` / `shared/`）
- 私有依赖走 Git 引用（不需要私有 pub server）

#### O.4 文档
- `README.md`：怎么跑、怎么打包、怎么换环境
- `ARCHITECTURE.md`：架构总览
- `docs/onboarding.md`：新人 1 天上手
- 关键决策记录 ADR（Architecture Decision Records）

---

### P. 弱网超时分级

- **接口超时分级**：商品列表 8s、商详 10s、下单 15s、支付 30s（写在 `dio` 配置）
- 弱网时展示 `EmptyState.network(onRetry: ...)` 提示用户手动重试

---

### Q. 测试策略

| 层 | 工具 | 必须覆盖 |
|---|---|---|
| 单元测试 | `flutter_test` + `mocktail` | Money 计算、地址解析、SKU 算法、Reducer/Notifier |
| Widget 测试 | `flutter_test` + `pumpWidget` | 关键页面（登录、下单、支付） |
| 集成测试 | `integration_test` | 主链路：登录 → 加购 → 下单 → 支付（mock 支付宝） |
| 性能测试 | `flutter drive --profile` | 列表 60fps、内存基线 |
| 快照测试 | `golden_toolkit` | EmptyState / AppButton 等通用组件视觉不回退 |

至少跑通**单测**和**关键 Widget 测试**，集成测试可按需。

---

### R. 用户体验杂项
- **复制订单号 / 商品号**：`Clipboard.setData` + Toast 提示

---

### S. 安全加固（按需）

- **Root / 越狱检测**：`flutter_jailbreak_detection`
- **抓包检测**：检测系统代理设置，发现则限制敏感操作
- **App 加固**：腾讯乐固 / 360 加固保（针对 Android，防反编译）
- **WebView 安全**：JS Bridge 必须域名白名单 + 调用方校验
- **运行环境检测**：模拟器检测，敏感页禁用

---

## 十二、关键技术决策（一句话理由）

1. **Riverpod**：比 Bloc 样板少，比 Provider 更安全。
2. **freezed + AsyncValue**：电商订单状态多，union types 自然适配；UI 三态统一。
3. **Dio + Retrofit**：拦截器链 + 注解 API，维护成本最低。
4. **Clean Architecture + Result 模式**：业务逻辑纯 Dart，无须 Flutter 即可单测；错误显式。
5. **支付/推送都先抽象接口**：本期只实装支付宝，未来加微信/极光零成本。
6. **空态/错误态一开始就统一**：晚做必返工。
7. **金额一定用 Decimal**：double 浮点累加错一分钱就是事故。
8. **隐私合规一开始就做**：上架被打回比开发慢一周更亏。
9. **全局异常捕获**：`runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError`，避免崩溃白屏。
10. **统一组件**：`AppNetworkImage` / `AppScaffold` / `AppWebView` / `AppButton` —— 业务层禁止裸用对应官方组件。
11. **多 Flavor 必上**：dev/test/pre/prod 四端共存，避免改 baseUrl 心智负担。
12. **设计 Token + ScreenUtil 双保险**：颜色/字号/间距/圆角全部走 token，且字号必 `.sp`、宽高必 `.w/.h`、圆角必 `.r`，禁止硬编码。

---

## 十三、推荐启动步骤

1. `flutter create` 初始化，写 `analysis_options.yaml`
2. 接入 `freezed / json_serializable / build_runner`，跑通代码生成
3. **架全局异常兜底**：`runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError`
4. **隐私合规**：`PrivacyGate` 守门，未同意不初始化任何 SDK
5. 搭 `core/network`：Dio 实例 + 4 个拦截器（Auth / Logger / **Status** / Error）+ 统一外壳模型
6. 搭 `shared/widgets` 统一组件：`AppScaffold`、`AppNetworkImage`、`AppButton`、`EmptyState`、`ErrorState`
7. 搭 `core/money` 金额值对象、`core/countdown` 倒计时控制器
8. 搭路由（go_router + 登录守卫）+ 主题 + DI（get_it）
9. 实现 `Splash` 启动流程（更新检查 → Token 校验 → 跳首页/登录）
10. 实现 `auth` 模块走通登录 → Token 写 `secure_storage` → 后续请求自动注入 → 后端 Token 过期错误码 → 跳登录闭环
11. 实现 `product` 列表（含 10-item 预加载、空态）+ 详情
12. 实现 `cart → order → 支付宝支付` 主链路（**真机调试** + `clientOrderId` 幂等）
13. 实现 `AppWebView` 纯展示容器（无 JS Bridge），跑通活动页 / 协议页加载
14. 完善 `address / coupon / user / message`
15. 多机型适配测试（4+ 机型） + 内存压测（进出页面 ×10）

---

## 十四、需要后端 / 产品确认

- **Token 过期错误码具体值**（如 `40001` / `401001` 等）→ 写到 `constants.dart` 的 `kTokenExpiredCode`
- Token 字段名（`Authorization: <token>` 还是 `Authorization: Bearer <token>`？或自定义 header `X-Token`？）
- Token 有效期？（影响是否提供"自动登录"、用户长时间不操作的体验）
- 响应外壳是否就是 `{code, msg, data}`？常见业务 code 列表（用于 [[code-error-mapping]]）？
- 支付宝开放平台账号 / 商户号是否已申请？
- H5 活动页 / 协议页域名 → 提前给出白名单（本期不规划 JS Bridge handler）
- ~~空态插画由设计提供还是用现成图标？~~ **已确认：设计交付**。需明确交付时间、文件命名规范、是否 1 套 @3x 还是 3 套 @1x/@2x/@3x
- 商品图片暂为普通 PNG 链接，**后续是否会迁 CDN**（如阿里云 OSS / 七牛）？若计划迁移，`AppNetworkImage` 内部留好替换 URL 缩放参数的钩子

---

## 十五、验证清单

**优先级说明**：🔴 P0 上线阻断 ｜ 🟡 P1 重要 ｜ ⚪ P2 锦上添花

- [ ] 🔴 `flutter doctor` 无报错，iOS / Android 双端能跑 demo
- [ ] 🔴 `build_runner` 一次性跑通 freezed + json + retrofit + injectable
- [ ] 🔴 登录 → Token 写入 `flutter_secure_storage` → 重启 App 仍登录态
- [ ] 🔴 后续每个接口请求头自动携带 Token
- [ ] 🔴 后端返回 Token 过期错误码 → 自动清 Token + 跳登录页 + 不弹 Toast
- [ ] 🟡 Token 过期后重新登录 → 回到原页面（保留 `from` 参数）
- [ ] 🔴 拦截器对 200 / 401 / 403 / 404 / 5xx / 超时 / 无网 **各有对应文案**
- [ ] 🔴 业务 code != 0 时 Toast `msg` 并抛 `BusinessFailure`
- [ ] 🟡 商品列表分页 + 下拉刷新
- [ ] 🟡 列表剩余 10 个 item 时自动加载下一页
- [ ] 🟡 后续 10 个主图被 `precacheImage`，快速滑动无白屏
- [ ] 🟡 前方 10 个详情数据被低优先级预取入内存
- [ ] 🟡 所有页面**空数据态**用 `EmptyState`，**网络错误态**用 `EmptyState.network`，**加载态**用 `CircularProgressIndicator`
- [ ] 🔴 真机走通支付宝沙箱支付
- [ ] 🟡 `flutter run --profile` 列表稳定 60fps
- [ ] 🟡 至少 4 款机型适配通过：iPhone 14 Pro（灵动岛）/ iPhone SE / 华为挖孔屏 / 小米折叠屏
- [ ] 🔴 所有页面使用 `AppScaffold`，无裸 `Scaffold` 调用
- [ ] 🟡 App 后台 → 前台：token 校验 + 关键数据刷新生效
- [ ] 🟡 进入后台时：Timer 停
- [ ] 🟡 商品详情页进入 → 返回 10 次，内存稳定无持续上涨
- [ ] 🟡 `leak_tracker` 在 debug 启动时无未释放对象告警
- [ ] 🟡 `imageCache.maximumSizeBytes` 已按机型调整
- [ ] ⚪ DevTools Memory tab 观察峰值 < 300MB（中端机基准）
- [ ] 🔴 业务层无裸 `CachedNetworkImage` / `Image.network`，统一走 `AppNetworkImage`
- [ ] 🟡 列表小图解码尺寸 ≤ 400px，详情大图 ≤ 1080px
- [ ] 🟡 H5 页面可正常加载（活动页、协议页、帮助中心）
- [ ] 🟡 H5 页面退出后 WebView 被销毁，内存回落
- [ ] 🟡 H5 域名白名单生效，非白名单链接走 `url_launcher` 系统浏览器
- [ ] 🔴 H5 不暴露 JS Bridge handler，原生不响应 H5 调用
- [ ] 🔴 首次启动弹隐私协议；未同意前**无任何 SDK 初始化**（断网抓包验证）
- [ ] 🟡 撤回隐私协议入口可用，撤回后清空敏感缓存
- [ ] 🔴 仅申请 `INTERNET / ACCESS_NETWORK_STATE`；相机 / 相册 / 通知 / 位置 / 麦克风等权限**不出现**在 manifest 与 Info.plist
- [ ] 🔴 各权限申请前有自定义解释弹窗，再调系统弹窗
- [ ] 🔴 设备标识只用 OAID / IDFV，无 IMEI / MAC / Android ID
- [ ] 🔴 `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError` 三处都接管
- [ ] 🔴 手动抛异常 → 控制台输出含完整堆栈
- [ ] 🔴 登录守卫：未登录访问"我的"→ 跳登录 → 登录成功回到"我的"
- [ ] 🔴 下单按钮快速连点 5 次只创建 1 单
- [ ] 🟡 搜索框输入 300ms 内不发请求（debounce）
- [ ] 🔴 金额：`0.1 + 0.2 = 0.3`（Decimal 计算，不出 `0.30000000000004`）
- [ ] 🟡 倒计时：同时展示多个倒计时（订单支付 + 验证码），只有 1 个 Timer 在跑
- [ ] 🟡 App 切后台 3 分钟回来，倒计时时间正确（wall clock 补偿）
- [ ] 🟡 启动 → Splash → 检查更新 → Token 校验 → 首页 全流程 < 1.5s
- [ ] 🟡 强更弹窗的"取消"按钮置灰且无法绕过
- [ ] 🔴 Android release 包跑通 `--obfuscate` 后无 SDK 反射崩溃
- [ ] ⚪ 单 ABI APK 体积 < 25MB
- [ ] 🟡 iOS 右滑返回手势在所有路由生效
- [ ] 🟡 Android 物理返回键拦截：底部 tab 第二次按退出 App
- [ ] 🟡 抓包：debug 配置允许 HTTPS 代理；release 拒绝抓包
- [ ] 🔴 下单接口包含 `clientOrderId`，重发请求不重复下单
- [ ] 🟡 结算页二次校验价格、优惠券、库存
- [ ] 🟡 登录后本地购物车与服务端合并成功
- [ ] 🔴 **UI 状态用 `AsyncValue.when`**，禁止 `bool isLoading + Error? + T?` 三字段
- [ ] 🔴 Repository 返回 `Result<Success, Failure>`，UI 层零 try-catch
- [ ] 🟡 商品列表返回时滚动位置 / 选中规格 / 筛选条件被恢复
- [ ] 🟡 控制台打印每条请求：方法、URL、Headers（Token 脱敏）、Body、HTTP code、响应 Body、耗时
- [ ] 🟡 错误请求带 ❌ 标记的红色前缀输出
- [ ] 🟡 Body 超过限制（请求 10KB / 响应 50KB）自动截断
- [ ] 🔴 `Authorization` / `Cookie` 在日志里始终脱敏
- [ ] 🔴 **4 套 Flavor 可在同一台手机共存**（dev / test / pre / prod 图标和名称各异）
- [ ] 🟡 dev / test 启动可见 Debug Menu，展示当前 Flavor + baseUrl + build 号（`package_info_plus`）
- [ ] 🟡 pre 环境支付宝走正式（小额），prod 走正式
- [ ] 🔴 release 包必须从 prod Flavor 出，禁止其他 Flavor 上架
- [ ] 🔴 iOS / Android 所有权限文案到位，无明文 HTTP（release）
- [ ] 🟡 表单：手机号/身份证/银行卡 校验生效，错误文案清晰
- [ ] 🔴 业务代码无硬编码颜色 / 字号 / 间距 / 圆角，全部走 `AppColors / AppFontSize / AppSpacing / AppRadius`
- [ ] 🔴 所有 `fontSize` 加 `.sp`，所有 `width/height/padding/margin` 加 `.w / .h`，所有 `BorderRadius` 加 `.r`
- [ ] 🟡 系统字体缩放设为 1.0 锁定（`textScaler: TextScaler.linear(1.0)`）
- [ ] 🟡 在 iPhone SE（小屏）/ iPhone 14 Pro Max（大屏）/ 平板 三种尺寸下页面布局不裂
- [ ] 🔴 价格、订单号等关键字段不被截断（`Flexible` / `FittedBox`）
- [ ] ⚪ 间距阶梯只用 4/8/12/16/20/24/32，无中间值
- [ ] 🟡 "我的 → 设置" 提供**注销账号**入口 + **个人信息收集清单**
- [ ] 🟡 关键页面有 Widget 测试（登录、下单、支付）
- [ ] ⚪ commit 全部符合 Conventional Commits 规范

---

## 关键文件

- `pubspec.yaml`
- `analysis_options.yaml`
- `lib/core/network/dio_client.dart`
- `lib/core/network/interceptors/status_interceptor.dart`（**本期重点**）
- `lib/core/network/interceptors/auth_interceptor.dart`
- `lib/core/network/api_response.dart`
- `lib/core/lifecycle/app_lifecycle_observer.dart`（**本期重点**）
- `lib/shared/widgets/empty_state.dart`（**本期重点**）
- `lib/shared/widgets/app_scaffold.dart`（**本期重点** — 统一 SafeArea/状态栏）
- `lib/shared/widgets/app_network_image.dart`（**本期重点** — 强制 memCacheWidth）
- `lib/shared/widgets/app_webview.dart`（**本期重点** — H5 纯展示容器，无 JS Bridge）
- `lib/features/payment/payment_gateway.dart`
- `lib/features/payment/alipay_service.dart`
- `lib/core/privacy/privacy_gate.dart`（首次启动隐私协议守门）
- `lib/core/permission/permission_service.dart`（场景化权限申请 + 解释弹窗）
- `lib/core/error/global_error_handler.dart`（`runZonedGuarded` 三层异常捕获）
- `lib/core/money/money.dart`（Decimal 值对象，统一加减乘除）
- `lib/core/countdown/countdown_controller.dart`（单 Timer 驱动多倒计时）
- `lib/shared/widgets/app_button.dart`（内置防抖/节流）
- `lib/features/update/version_check_service.dart`（强更/普更）
- `lib/features/splash/splash_page.dart`（启动流程编排）
- `lib/core/theme/tokens.dart`（颜色/字号/间距/圆角 token，业务侧禁止硬编码）
- `lib/core/network/interceptors/logger_interceptor.dart`（**本期重点** — 完整链路日志 + 脱敏）
- `lib/core/flavor/flavor.dart`、`lib/core/flavor/bootstrap.dart`
- `lib/main_dev.dart` / `lib/main_test.dart` / `lib/main_pre.dart` / `lib/main_prod.dart`
- `env/dev.json` / `env/test.json` / `env/pre.json` / `env/prod.json`
- `lib/features/account/account_deletion_page.dart`（注销账号合规入口）
- `android/app/build.gradle`（productFlavors 配置）
- `ios/Runner/Info.plist`（权限说明、URL Schemes、ATS）
- `android/app/src/main/AndroidManifest.xml`（权限、queries、FileProvider）
