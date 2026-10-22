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


## Diagramas UML vigentes y trazabilidad

Consulta el [proyecto maestro Astah](../docs/diagrams/Heliostrand_Modelos_Completos.asta), el [Draw.io editable](../docs/diagrams/Heliostrand_Diagramas_Completos.drawio) y la [guía de modelado](../docs/diagrams/README.md). La aplicación móvil tiene diagramas de clases, casos de uso y actividades en ambos formatos.

`BaseTelemetryService` es una clase abstracta de Dart usada como **contrato de interfaz** por `NfcService` y `SimulationService` mediante `implements`; UML emplea relaciones de realización. `_DashboardScreenState` administra los ciclos de vida de esos dos servicios, y `NfcService` crea su parser privado, por lo que se muestran tres composiciones. El historial de `RobotTelemetry` es una asociación normal.

El escaneo usa `FlutterNfcKit.poll(timeout: Duration(seconds: 10))`. El servicio de simulación emite por defecto cada **1500 ms**. Para comprobar las rutas de las seis pestañas Draw.io, desde el directorio raíz ejecuta:

```bash
python3 tools/validate_uml_diagrams.py
```

Utiliza el SDK `/home/ramsescb/flutter/bin/flutter` (Flutter 3.47.2, Dart 3.13.2) en este entorno; la instalación antigua ubicada en `~/Tools/flutter` no satisface el SDK mínimo del `pubspec.yaml`.
