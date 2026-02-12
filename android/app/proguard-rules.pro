# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Isar Database
-keep class dev.isar.** { *; }
-keep class **.isar.** { *; }

# Supabase
-keep class io.supabase.** { *; }

# Keep model classes (Isar collections)
-keep class com.wzh.lifelog.** { *; }

# Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
