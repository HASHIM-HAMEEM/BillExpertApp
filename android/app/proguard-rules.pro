# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep all classes in the main package
-keep class com.example.invoice_app.** { *; }

# Keep Hive related classes
-keep class com.example.invoice_app.** { *; }
-keep class * extends io.flutter.embedding.android.FlutterActivity

# Keep Google Mobile Ads classes
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Keep PDF generation classes
-keep class com.example.invoice_app.** { *; }

# Keep data models
-keep class * extends org.example.invoice_app.** { *; }
