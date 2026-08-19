# LastCheck release R8 规则

# androidx.work / Room：R8 会裁掉 WorkDatabase_Impl 的反射构造函数，导致启动崩溃
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
-keepclassmembers class * extends androidx.room.RoomDatabase { <init>(); }

# 保留应用自身的类（MainActivity 等）
-keep class com.lastcheck.lastcheck_app.** { *; }
