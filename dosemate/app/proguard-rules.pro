# DoseMate keeps no reflection-based serialisation; Room, Hilt and Compose ship their own rules.
# Keep enum names because they are stored in the database and in backups.
-keepclassmembers enum com.dosemate.** { *; }
-keep class com.dosemate.app.widget.** { *; }
