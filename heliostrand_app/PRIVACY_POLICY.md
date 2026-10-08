# Política de Privacidad — Theo Jansen Solar Tracker

**Última actualización:** 3 de octubre de 2026  
**Desarrollador:** RamsesCB  
**Aplicación:** Theo Jansen Solar Tracker (Móvil Flutter & Desktop Java)

---

## 1. Introducción
La aplicación **Theo Jansen Solar Tracker** ha sido desarrollada como una herramienta de código abierto para el monitoreo educativo y científico de telemetría de robots solares bio-inspirados tipo Theo Jansen. Esta Política de Privacidad describe el tratamiento de datos y los permisos utilizados por la aplicación. La distribución mediante una tienda concreta, cuando exista, se rige adicionalmente por las políticas vigentes de esa plataforma.

---

## 2. Recopilación y Uso de Información Personal
- **Cero Recopilación de Datos Personales:** La aplicación **NO recopila, almacena, transmite ni comparte ningún dato personal** identificable de los usuarios (tales como nombre, correo electrónico, número de teléfono, ubicación geográfica, identificadores de publicidad ni contactos).
- **Sin Cuentas de Usuario:** No se requiere registro, creación de cuentas ni autenticación en servidores externos para utilizar la aplicación.
- **Sin Rastreo Publicitario:** La aplicación no incluye bibliotecas de analítica comercial, rastreadores con fines publicitarios ni anuncios.

---

## 3. Uso de Sensores, Conectividad y Diagnósticos

### A. Comunicación de Campo Cercano (NFC) — `android.permission.NFC`
- **Propósito:** Leer localmente el búfer binario de 12 bytes emitido por el transpondedor NFC montado en el robot (sensores de luz LDR, ángulos de servomotores, inversiones de polaridad del motor, voltaje y porcentaje de batería).
- **Destino:** Toda la decodificación se procesa exclusivamente en la memoria local del dispositivo mediante CRC-8. Las lecturas de telemetría no se transmiten a servidores externos.

### B. Reporte Técnico de Fallos y Estabilidad (Sentry) — `android.permission.INTERNET`
- **Propósito:** Monitorear la estabilidad y resolver caídas imprevistas de la aplicación mediante la plataforma de código abierto Sentry.
- **Datos técnicos procesados:** Pila de llamadas de error (stack trace), modelo de dispositivo, arquitectura de procesador y versión de Android.
- **Seguridad:** Los datos técnicos se transmiten mediante conexión cifrada HTTPS/TLS y no contienen datos personales identificables (PII).

### C. Consulta de Versión Mínima Requerida — `android.permission.INTERNET`
- **Propósito:** Consultar un archivo JSON público por HTTPS para notificar al usuario cuando una actualización obligatoria esté disponible en Google Play Store. No se envía ninguna información del usuario en esta consulta.

### D. Exportación Local de Datos
- **Propósito:** Permitir al usuario exportar manualmente sus sesiones de telemetría a formato CSV o JSON para análisis académico o personal. Solo se genera el archivo cuando el usuario pulsa explícitamente el botón de exportación.

---

## 4. Declaración de Seguridad de los Datos (Google Play Data Safety)

Para efectos del cuestionario oficial de Google Play Console:
- **¿La app recopila o comparte datos del usuario?**
  - Datos personales: **NO**.
  - Diagnósticos y rendimiento (Información sobre fallos / Crash logs): **SÍ**, recopilados automáticamente por Sentry exclusivamente con fines de corrección de errores y funcionalidad de la app.
- **¿Los datos se transfieren a través de una conexión segura?** **SÍ**, todos los reportes técnicos se transmiten mediante HTTPS/TLS cifrado.
- **¿Los datos se comparten con terceros?** **NO**, no se venden ni se comparten con redes publicitarias ni intermediarios de datos.
- **¿El usuario puede solicitar la eliminación de datos?** Los datos de telemetría son locales y se eliminan al limpiar datos o desinstalar la app. Los registros de diagnóstico de fallos en Sentry rotan y se eliminan periódicamente según políticas de retención técnica.

---

## 5. Contacto
Si tienes preguntas o inquietudes acerca de esta Política de Privacidad o del funcionamiento del proyecto, puedes abrir un issue o comunicarte a través del repositorio oficial de GitHub:
- **Repositorio:** [https://github.com/RamsesCB/heliostrand-nfc-core-cpp](https://github.com/RamsesCB/heliostrand-nfc-core-cpp)
- **Autor:** RamsesCB

