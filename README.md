# Heliostrand NFC Core

[![CI](https://github.com/RamsesCB/heliostrand-nfc-core-cpp/actions/workflows/ci.yml/badge.svg)](https://github.com/RamsesCB/heliostrand-nfc-core-cpp/actions/workflows/ci.yml)

Monorepositorio para un robot Theo Jansen con seguimiento solar biaxial, telemetría V2, persistencia NFC NTAG213 y clientes Java/Flutter.

## Estado de versiones

- v1.0.0 es una release legada y su tag precede la remediación V2 actual. No debe usarse como referencia del código de main.
- El código fuente actual está preparado como 1.1.0.
- Las nuevas releases se generan desde tags v* mediante .github/workflows/release.yml. Firmware, JAR, APK y SHA256SUMS.txt nacen del mismo commit.

## Arquitectura real

El Arduino genera un frame V2 de 12 bytes. El frame sale por dos transportes independientes:

1. UART binario: AA 55 + payload de 12 bytes + CR LF.
2. PN532 por SPI: el PN532 persiste dos slots alternos en NTAG213: páginas 4-7 y 8-11.

El PN532 actúa como lector/escritor. Los clientes Desktop y Mobile leen el tag pasivo NTAG213; no leen directamente al PN532.

Desktop Java usa PC/SC. Flutter usa la antena NFC del teléfono.

## Fuente única de verdad

La definición completa del frame no se duplica en README:

- [Protocolo V2 normativo](docs/protocol/telemetry-v2.md)
- [Pinout y batería](docs/hardware/pinout.md)
- [Vectores dorados compartidos](test/vectors/golden_telemetry_vectors.json)

Resumen: 12 bytes exactos, V2 en bits 7-6, estado del motor en bits 5-4, dirección lumínica en bits 3-0, batería uint16 Big-Endian y CRC-8 con polinomio 0x07.

## NFC y resistencia de EEPROM

El writer NFC:

- valida Capability Container NTAG213;
- permite fijar un UID esperado en TheoJansenConfig.h; si no se configura, bloquea el primer UID válido por arranque;
- no usa CRC ni sequenceNumber para decidir cambios de estado;
- exige 5 minutos entre escrituras posteriores a la primera;
- refresca un estado sin cambios a los 15 minutos;
- usa doble buffer: slot A 4-7 y slot B 8-11;\n- escribe el commit de cada slot al final;\n- verifica payload y commit mediante read-after-write.

La escritura multipágina no es atómica. CRC-8 detecta errores accidentales con alta probabilidad, pero no proporciona autenticación.

## Hardware

| Recurso | Asignación |
|---|---|
| LDR | A0, A1, A2, A3 |
| Batería Li-ion 1S | A4, divisor 20 kOhm / 20 kOhm + 100 nF |
| Motor L298N | D3 ENA, D5 IN1, D6 IN2 |
| PN532 SPI | D4 CS, D11 MOSI, D12 MISO, D13 SCK |
| Servos | D9 Pitch, D10 Yaw |
| LED | D7 |

## Estructura

- include/: cabeceras firmware
- src/: firmware
- test/vectors/: vectores normativos
- test/test_telemetry/: tests C++ nativos
- tools/: generadores
- AplicacionJava/: Java 21, Swing y PC/SC
- heliostrand_app/: Flutter
- docs/protocol/: especificación normativa del protocolo
- docs/hardware/: especificación normativa de hardware
- .github/workflows/ci.yml: integración continua
- .github/workflows/release.yml: releases basadas en tag

La UI Java usa el namespace com.ramsescb.heliostrand.desktop.

## Compilación y pruebas

### Firmware

    python3 tools/generate_golden_vectors_header.py
    pio run -e uno
    pio test -e native
    pio check -e uno --skip-packages

El UART es un canal binario de máquina; no se mezclan logs de texto con frames.

### Java Desktop

    cd AplicacionJava
    mvn clean test package
    java --add-modules java.smartcardio -jar target/AplicacionJava-1.1.0-jar-with-dependencies.jar

El cliente Desktop actual consume NFC mediante PC/SC. No se anuncia un lector UART Java porque esa capa no existe.

### Flutter

Versión de referencia: Flutter 3.47.2.

    cd heliostrand_app
    flutter pub get
    flutter analyze
    flutter test
    flutter build apk --debug

Un build release exige android/key.properties y una clave de firma configurada explícitamente. No existe fallback automático a firma debug. Para v1.1.0 se conserva el mismo certificado de v1.0.0 para mantener compatibilidad de actualización.

## Contratos de cliente

Java y Flutter:

- exigen 12 bytes;
- verifican CRC;
- rechazan versiones distintas de V2;
- rechazan códigos reservados;
- validan rangos físicos;
- muestran batería 0 mV como N/D;
- deduplican por UID + sequenceNumber;
- limitan el historial UI a 500 muestras.

Los tests Java y Dart leen directamente el JSON normativo. C++ genera su cabecera de prueba desde ese mismo archivo.

## Descargas v1.1.0

Cuando el tag v1.1.0 esté publicado, estos enlaces apuntan a los artefactos construidos desde ese mismo commit:

- [Android APK](https://github.com/RamsesCB/heliostrand-nfc-core-cpp/releases/download/v1.1.0/heliostrand-app.apk)
- [Java 21 JAR](https://github.com/RamsesCB/heliostrand-nfc-core-cpp/releases/download/v1.1.0/AplicacionJava-1.1.0-jar-with-dependencies.jar)
- [Firmware Arduino HEX](https://github.com/RamsesCB/heliostrand-nfc-core-cpp/releases/download/v1.1.0/heliostrand-firmware.hex)
- [SHA-256 checksums](https://github.com/RamsesCB/heliostrand-nfc-core-cpp/releases/download/v1.1.0/SHA256SUMS.txt)

El artefacto Java también se publica en GitHub Packages con coordenadas Maven:

    com.github.ramsescb:AplicacionJava:1.1.0

## Release 1.1.0

release.yml valida que el tag coincida con las versiones Maven/Flutter, ejecuta pruebas y publica:

- heliostrand-firmware.hex
- AplicacionJava-<version>-jar-with-dependencies.jar
- heliostrand-app.apk
- SHA256SUMS.txt

Android requiere los secrets ANDROID_KEYSTORE_BASE64, ANDROID_STORE_PASSWORD, ANDROID_KEY_PASSWORD y ANDROID_KEY_ALIAS.

No se debe mover un tag publicado para hacerlo apuntar a otro commit.

## Documentación

- [DOCUMENTS.md](DOCUMENTS.md)
- [RULES.md](RULES.md)
- [CONSTITUTION.md](CONSTITUTION.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [LICENSE.md](LICENSE.md)

## Licencia

Proyecto Source-Available bajo HELS-AEL 1.0, licencia personalizada de atribución obligatoria y no OSI-approved. Consulte LICENSE.md para los términos completos.
