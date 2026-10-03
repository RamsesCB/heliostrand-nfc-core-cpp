# Heliostrand Mobile

Cliente Flutter del sistema Heliostrand NFC Core.

## Responsabilidades

- leer los dos slots de telemetría del NTAG213;
- validar commit, generación, CRC-8 y semántica del Protocolo V2;
- elegir el slot válido más reciente y usar el anterior como fallback;
- deduplicar muestras por UID + sequenceNumber;
- mostrar batería desconectada como N/D;
- conservar hasta 500 muestras en memoria;
- exportar JSON y CSV;
- ofrecer un generador sintético coherente con V2.

## Entorno de referencia

- Flutter 3.47.2
- Dart 3.13.2
- Android con NFC para lectura real

## Verificación

    flutter pub get
    flutter analyze
    flutter test
    flutter build apk --debug

Los builds release requieren android/key.properties y una keystore de producción. No existe fallback a firma debug.

La especificación normativa del protocolo está en ../docs/protocol/telemetry-v2.md.
