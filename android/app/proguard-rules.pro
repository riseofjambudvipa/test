# Preserve our own JNI classes
-keep class com.capstudio.** { *; }
-keepclassmembers class com.capstudio.** { *; }
-dontwarn com.capstudio.**

# Preserve antonkarpenko ffmpegkit JNI classes
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keepclassmembers class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**

# Preserve arthurhr ffmpegkit JNI classes
-keep class com.arthurhr.ffmpegkit.** { *; }
-keepclassmembers class com.arthurhr.ffmpegkit.** { *; }
-dontwarn com.arthurhr.ffmpegkit.**

# Preserve general ffmpegkit classes just in case
-keep class com.ffmpegkit.** { *; }
-keepclassmembers class com.ffmpegkit.** { *; }
-dontwarn com.ffmpegkit.**

# Preserve all JNI / native method mappings
-keepclasseswithmembernames class * {
    native <methods>;
}

-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
