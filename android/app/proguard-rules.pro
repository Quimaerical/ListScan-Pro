# ProGuard / R8 rules for ListScan PRO

# Google ML Kit Text Recognition:
# The plugin includes initialize methods referencing optional Asian & Devanagari language modules.
# When those optional dependencies are omitted, R8 warns about missing classes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
