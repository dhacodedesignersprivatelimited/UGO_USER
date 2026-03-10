# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Razorpay SDK - prevent ClassNotFoundException and ProGuard stripping
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Standard rules
-dontwarn io.flutter.embedding.**
-ignorewarnings
