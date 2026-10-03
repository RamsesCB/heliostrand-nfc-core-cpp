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
- **Sin Rastreo ni Telemetría de Usuario:** La aplicación no incluye bibliotecas de analítica comercial, rastreadores de terceros ni plataformas de publicidad.

---

## 3. Uso de Sensores y Permisos del Dispositivo
La aplicación solicita únicamente los permisos estrictamente necesarios para su funcionamiento local con el robot:

### A. Comunicación de Campo Cercano (NFC) — `android.permission.NFC`
- **Propósito:** Leer localmente el búfer binario de 12 bytes emitido por el transpondedor NFC montado en el robot (sensores de luz LDR, ángulos de servomotores, inversiones de polaridad del motor, voltaje y porcentaje de batería).
- **Destino:** Toda la decodificación se procesa en la memoria RAM del propio dispositivo mediante el algoritmo CRC-8. Ninguna lectura se envía a servidores en la nube.

### B. Almacenamiento Local y Compartir Archivos
- **Propósito:** Permitir al usuario exportar manualmente sus sesiones de telemetría a formato JSON (`.json`) para análisis estadístico propio o académico.
- **Acceso:** Solo se crea un archivo temporal cuando el usuario pulsa explícitamente el botón "Exportar / Compartir".

---

## 4. Declaración de Seguridad de Datos (Google Play Data Safety)
Para efectos del formulario de Seguridad de los Datos de Google Play Console:
- **¿La app recopila o comparte datos de usuario?** NO.
- **¿Los datos se transfieren a través de una conexión segura?** No se transfieren datos a la red.
- **¿El usuario puede solicitar la eliminación de datos?** Los datos se almacenan exclusivamente de forma local y se eliminan al desinstalar la app o limpiar la caché.

---

## 5. Contacto
Si tienes preguntas o inquietudes acerca de esta Política de Privacidad o del funcionamiento del proyecto, puedes abrir un issue o comunicarte a través del repositorio oficial de GitHub:
- **Repositorio:** [https://github.com/RamsesCB/heliostrand-nfc-core-cpp](https://github.com/RamsesCB/heliostrand-nfc-core-cpp)
- **Autor:** RamsesCB
