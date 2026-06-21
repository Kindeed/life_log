# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Isar Database
-keep class dev.isar.** { *; }
-keep class **.isar.** { *; }

# Supabase
-keep class io.supabase.** { *; }

# google_mlkit_text_recognition references optional scripts even when the app
# only wires the Chinese recognizer dependency.
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep model classes (Isar collections)
-keep class com.wzh.lifelog.** { *; }

# Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
