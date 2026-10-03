# Heliostrand NFC Core — Documento técnico y manual operativo

> Versión de código: 1.1.0
> Protocolo normativo: [docs/protocol/telemetry-v2.md](docs/protocol/telemetry-v2.md)
> Hardware normativo: [docs/hardware/pinout.md](docs/hardware/pinout.md)

## 1. Alcance

Heliostrand integra Arduino Uno, cuatro LDR, dos servos, un motor DC con L298N, PN532 SPI y un tag NTAG213. El firmware genera telemetría V2; el tag conserva snapshots de baja frecuencia y las aplicaciones Desktop/Mobile los validan antes de mostrarlos.

## 2. Seguimiento solar

- Pitch: D9, restringido a 15..165 grados.
- Yaw: D10, restringido a 10..170 grados.
- LDR: A0 Norte, A1 Sur, A2 Oeste, A3 Este.
- Deadband: 12 unidades de la lectura cuantizada de 8 bits.
- Paso de servo: 2 grados por actualización.

## 3. Batería

El hardware actual está definido para Li-ion 1S:

- rango nominal para porcentaje: 3000..4200 mV;
- ventana semántica admisible: 2500..5000 mV;
- divisor 20 kOhm / 20 kOhm;
- capacitor recomendado 100 nF de A4 a GND;
- 8 muestras promediadas tras una lectura de descarte;
- Vcc estimada con la referencia interna del ATmega328P;
- lectura no válida codificada como 0 mV y mostrada como N/D.

## 4. Protocolo V2

La tabla bit a bit existe exclusivamente en [docs/protocol/telemetry-v2.md](docs/protocol/telemetry-v2.md). README y este documento no la duplican.

Invariantes:

- 12 bytes exactos;
- CRC-8 0x07;
- Big-Endian para batería;
- versión 2 obligatoria;
- motor: detenido, adelante o atrás;
- dirección: equilibrado, norte, sur, este u oeste;
- códigos reservados rechazados;
- batería 0 = sensor no disponible.

Los vectores normativos están en test/vectors/golden_telemetry_vectors.json.

## 5. Persistencia NFC

El PN532 escribe el NTAG213. El smartphone o lector PC/SC lee el NTAG213, no al PN532.

Política del writer:

1. validar Capability Container NTAG213;
2. exigir UID de 7 bytes;
3. si NFC_ENFORCE_EXPECTED_UID=1, exigir el UID configurado; si no, bloquear el primer UID válido durante el arranque;
4. primera escritura inmediata;
5. intervalo mínimo posterior de 5 minutos;
6. refresh sin cambios a los 15 minutos;
7. ignorar secuencia y CRC al decidir si cambió el estado físico;
8. escribir páginas 4, 5 y 6;
9. releer las tres páginas y comparar;
10. actualizar estado interno solo tras verificación exitosa.

La escritura física sigue sin ser atómica, pero el doble buffer evita reemplazar el último slot válido hasta que el nuevo payload esté verificado y comprometido. CRC reduce el riesgo de aceptar corrupción accidental, pero no autentica datos.

## 6. UART

SerialTelemetryTransport es responsable del UART de máquina:

    0xAA 0x55 | payload V2 de 12 bytes | 0x0D 0x0A

No se insertan logs de texto entre frames. El cliente Java actual no implementa lector serial; su vía de hardware es PC/SC.

## 7. Desktop Java 21

Namespace UI/controlador: com.ramsescb.heliostrand.desktop.

NfcServiceManager:

- enumera terminales PC/SC;
- intenta UID real mediante FF CA 00 00 00;
- lee 12 bytes desde bloque/página 4;
- libera Card en finally;
- distingue lector disponible de tag presente;
- no vuelve a publicar la misma secuencia del mismo UID.

La UI Swing actualiza componentes en EDT mediante SwingUtilities.invokeLater.

El historial y JTable se limitan a 500 muestras.

Ejecución:

    cd AplicacionJava
    mvn clean test package
    java --add-modules java.smartcardio -jar AplicacionJava-1.1.0-jar-with-dependencies.jar

## 8. Flutter

El dashboard:

- valida V2 con el mismo contrato de Java;
- muestra N/D para batería desconectada;
- conserva 500 muestras;
- evita setState después de desmontar;
- suprime lecturas duplicadas por UID/secuencia;
- exporta JSON y CSV.

El CSV usa CRLF y escaping de comillas, comas y saltos de línea. Encabezado real:

    version,sequenceNumber,timestamp,tagUid,ldrNorth,ldrSouth,ldrWest,ldrEast,ldrAverage,direction,pitchAngle,yawAngle,voltageMv,batteryPercent,batteryValid,polarityReversals,motorState

Lectura móvil:

1. activar NFC;
2. iniciar escaneo;
3. acercar el teléfono al tag NTAG213;
4. la app intenta Type 2 READ 30 04 y toma los primeros 12 bytes;
5. valida frame y frescura.

## 9. Simulación

Las simulaciones Java y Flutter respetan el dominio V2:

- versión 2;
- secuencia incremental modular;
- UID estable por sesión;
- batería 3.2..4.2 V;
- servos dentro de límites;
- motor adelante/atrás/detenido.

Son generadores sintéticos; no constituyen modelos físicos de irradiancia.

## 10. Verificación

C++:

    python3 tools/generate_golden_vectors_header.py
    pio run -e uno
    pio test -e native
    pio check -e uno --skip-packages

Java:

    cd AplicacionJava
    mvn clean test package

Flutter:

    cd heliostrand_app
    flutter analyze
    flutter test
    flutter build apk --debug

ci.yml ejecuta estas capas en push/PR a main.

## 11. Releases

v1.0.0 se conserva como referencia histórica; su tag no representa esta remediación.

A partir de v1.1.0, el tag es la fuente de los binarios. release.yml:

- exige coincidencia entre tag, Maven y Flutter;
- ejecuta tests;
- construye firmware, JAR y APK firmado;
- publica SHA-256;
- no permite release Android con clave debug.

No se debe mover un tag ya publicado.
