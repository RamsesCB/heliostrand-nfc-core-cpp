# Heliostrand Release (R8)
# Conservar metadatos necesarios para stack traces y anotaciones.
-keepattributes SourceFile,LineNumberTable,Signature,*Annotation*,InnerClasses,EnclosingMethod
# Las librerias Flutter/Android aportan sus propias reglas consumer ProGuard.
# No usamos DTOs Java con Gson/Moshi/Retrofit en esta version.
