// AuthService.handleTokenExpired 需要在 Widget 树外部导航
// 用可变全局持有导航函数，在 app.dart 初始化后注入，避免循环导入
typedef NavigateFn = void Function(String path);

NavigateFn? _fn;

void registerNavigateFn(NavigateFn fn) => _fn = fn;

void globalNavigate(String path) => _fn?.call(path);
