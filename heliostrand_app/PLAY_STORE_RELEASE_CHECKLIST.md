# Heliostrand — preparacion para lanzamiento Play Store

> Proyecto: /home/ramsescb/Projects/arduino_app_Fundamentos/heliostrand_app
> No subir el keystore ni android/key.properties a Git.

## 1. Crear firma de subida (paso manual obligatorio)

En una terminal local, desde la raiz de heliostrand_app:

```bash
keytool -genkeypair -v \
  -keystore android/heliostrand-upload-key.jks \
  -storetype PKCS12 -alias heliostrand-upload \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -dname "CN=Heliostrand Upload, OU=Mobile, O=Heliostrand, L=Huarmey, ST=Ancash, C=PE"
```

Cuando lo solicite, ingresa una contraseña de al menos 12 caracteres y
conservala en un gestor seguro. No pongas la contraseña en el comando.

Crea `android/key.properties` con el siguiente contenido (rellena tus claves):

```properties
storePassword=REEMPLAZAR_CON_TU_CONTRASENA
keyPassword=REEMPLAZAR_CON_TU_CONTRASENA
keyAlias=heliostrand-upload
storeFile=../heliostrand-upload-key.jks
```

La ruta storeFile se resuelve desde android/app. Los dos archivos estan ignorados
por .gitignore. Protegelos con `chmod 600 android/key.properties android/heliostrand-upload-key.jks`.
Haz una copia de seguridad cifrada del .jks y de la contraseña en lugares separados.

**Nota:** esta clave es de SUBIDA, Google Play App Signing gestionara la de
firma de distribucion cuando se active en la consola.

## 2. Configurar reportes de fallos

Crear proyecto en https://sentry.io/ y obtener el DSN de Flutter.
`SENTRY_DSN` se inyecta al compilar con --dart-define.
Mientras el DSN este vacio no se transmiten reportes.
Sentry registra errores de Flutter y Android de acuerdo con su SDK.
Validar con un fallo controlado en una compilacion de prueba, nunca en usuarios.

## 3. Configurar version gating

Publicar JSON por HTTPS, por ejemplo:

```json
{"min_required_version": 2}
```

El numero representa el **versionCode** Android, no 1.1.0.
La aplicacion actual es 1.1.0+2. Antes de bloquear version 2,
publica una version con versionCode 3 o superior en Google Play.
Si la politica responde un minimo mayor que el codigo local, la app
bloquea navegacion y muestra boton de Play Store. Con errores de red
usa el ultimo minimo validado y almacenado; en primera instalacion
sin acceso a red no puede consultar una politica remota y permite entrar.

Define la URL por compilacion usando VERSION_POLICY_URL. En ausencia de URL
el bloqueo remoto queda **desactivado**.

## 4. Construir AAB firmado

```bash
cd /home/ramsescb/Projects/arduino_app_Fundamentos/heliostrand_app
/home/ramsescb/flutter/bin/flutter pub get
/home/ramsescb/flutter/bin/flutter analyze
/home/ramsescb/flutter/bin/flutter test
/home/ramsescb/flutter/bin/flutter build appbundle --release \
  --dart-define=VERSION_POLICY_URL=https://TU-DOMINIO/heliostrand-version.json \
  --dart-define=SENTRY_DSN=https://TU-DSN-REAL \
  --dart-define=APP_ENV=production
```

Salida: `build/app/outputs/bundle/release/app-release.aab`.
Firma y certificado deben verificarse antes de subirlo a Play Store Console.
En pruebas internas, instalar el **Release firmado**, validar NFC real,
CRC de tramas, exportacion CSV/JSON, offline, y version obligatoria.
No confundir APK Debug con Release.

## 5. Monitoreo primeras 48 horas

Revisar Android Vitals/Play Console, panel Sentry, las tendencias de fallos
por dispositivo, Android API, version de app y flujos NFC. Corregir crashes
criticos y preparar rollback / despliegue por etapas.
