# Flutter Core ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep App specific classes
-keep class com.hyperLocal.seller.** { *; }

# Attributes required for reflection, serialization, and annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Firebase & Google Play Services
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }

# Google Maps
-keep class com.google.android.libraries.maps.** { *; }
-dontwarn com.google.android.libraries.maps.**

# Audio & Media
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-keep class xyz.luan.audioplayers.** { *; }

# InAppWebView & WebView
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Networking (OkHttp / Okio / Dio / Gson)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class com.google.gson.** { *; }

# JNI & Quill Native Bridge
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn com.google.errorprone.annotations.**
