# SQLCipher (encrypted database) uses JNI; keep its classes intact.
-keep class net.zetetic.** { *; }
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**
# WorkManager background callbacks
-keep class dev.fluttercommunity.workmanager.** { *; }
# Google Play Services / Credential Manager (Google Sign-In)
-keep class com.google.android.gms.auth.** { *; }
-keep class androidx.credentials.** { *; }
-dontwarn com.google.errorprone.annotations.**
# flutter_local_notifications stores scheduled alarms with Gson (needs generics).
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
