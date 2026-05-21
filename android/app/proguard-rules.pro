# Flutter 混淆规则
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 支付宝 SDK（tobias）
-keep class com.alipay.** { *; }
-keep class com.eg.android.AlipayGphone.** { *; }

# JSON 反射（freezed / json_serializable 生成类）
-keepattributes *Annotation*
-keepattributes Signature
-keep class * extends java.lang.annotation.Annotation { *; }

# Dio / OkHttp
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
