# ProGuard / R8 rules for ListScan PRO

# Google ML Kit Text Recognition plugin & native classes
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.** { *; }

# Suppress warnings for unused optional language modules
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**
-dontwarn com.google_mlkit_text_recognition.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Suppress warnings for Google Play Core deferred components
-dontwarn com.google.android.play.core.**

# Keep attributes required for reflection & annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
