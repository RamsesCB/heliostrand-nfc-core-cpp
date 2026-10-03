# Heliostrand Telemetry Protocol V2 — Especificación normativa

> Fuente única de verdad. Cualquier implementación C++, Java o Dart debe ajustarse a este documento y a test/vectors/golden_telemetry_vectors.json.

## 1. Contrato binario

- Longitud: 12 bytes exactos.
- Enteros de 16 bits: Big-Endian.
- Integridad: CRC-8, polinomio 0x07, init 0x00, calculado sobre bytes 0..10.
- Payload: 3 páginas de 4 bytes. Persistencia robusta: slot A en páginas 4-7 y slot B en páginas 8-11; la cuarta página de cada slot es un commit.
- CRC-8 detecta errores accidentales; no es autenticación y no garantiza detectar toda modificación posible.

| Offset | Campo | Tipo | Semántica normativa |
|---|---|---|---|
| 0 | headerFlags | uint8 | bits 7-6: versión (0b10=V2); bits 5-4: motor (00 detenido, 01 adelante, 10 atrás, 11 reservado); bits 3-0: luz (0 equilibrado, 1 norte, 2 sur, 3 este, 4 oeste; 5..15 reservados) |
| 1 | sequenceNumber | uint8 | contador circular del productor, 0..255 |
| 2 | ldrNorth | uint8 | ADC de 10 bits cuantizado con raw >> 2 |
| 3 | ldrSouth | uint8 | idem |
| 4 | ldrWest | uint8 | idem |
| 5 | ldrEast | uint8 | idem |
| 6 | servoPitch | uint8 | protocolo 0..180 grados; firmware actual 15..165 |
| 7 | servoYaw | uint8 | protocolo 0..180 grados; firmware actual 10..170 |
| 8-9 | batteryMilliVolts | uint16 BE | 0 = no disponible; campo 0..65535; hardware 1S admite 2500..5000 mV y opera nominalmente en 3000..4200 mV |
| 10 | polarityReversals | uint8 | inversiones directas ADELANTE ↔ ATRÁS |
| 11 | crc8 | uint8 | CRC-8 de bytes 0..10 |

## 2. Validación obligatoria

El receptor debe, en este orden:

1. Exigir length == 12.
2. Verificar CRC-8.
3. Exigir version == 2.
4. Rechazar motorCode == 3.
5. Rechazar lightDirection fuera de 0..4.
6. Rechazar ángulos mayores a 180.
7. Aceptar batería 0 como N/D; si es distinta de cero, exigir 2500..5000 mV.

Java y Dart implementan estas reglas con excepciones explícitas. Los mismos vectores JSON se consumen en C++, Java y Dart.

## 3. Frescura

sequenceNumber identifica una muestra distinta de la última observada para el mismo UID. Los clientes mantienen el último número de secuencia por tag y no vuelven a insertar una lectura si el mismo UID conserva la misma secuencia.

La secuencia es modular y no es un reloj absoluto. El timestamp creado por un cliente significa hora de recepción, no hora física de captura.

## 4. CRC-8

Algoritmo:

    crc = 0x00
    for byte in D[0..10]:
        crc ^= byte
        repeat 8:
            if crc & 0x80:
                crc = ((crc << 1) ^ 0x07) & 0xFF
            else:
                crc = (crc << 1) & 0xFF

## 5. Persistencia NTAG213

Cada slot ocupa cuatro páginas: tres de payload y una de commit. El writer alterna entre slot A (4-7) y slot B (8-11). El slot anterior permanece válido mientras se escribe el nuevo; el commit se escribe al final. El firmware reduce el riesgo mediante:

- validación del Capability Container NTAG213 E1 10 12;
- bloqueo al primer UID NTAG213 válido detectado durante el arranque;
- escritura inicial inmediata;
- intervalo mínimo de 5 minutos entre escrituras posteriores;
- refresh de un estado sin cambios solo después de 15 minutos;
- detección de cambios significativos sobre estado, LDR, servos, batería e inversiones;
- exclusión deliberada de sequenceNumber y crc8 del detector de cambios;
- read-after-write del payload antes del commit y verificación posterior del commit;\n- selección por contador de generación modular, con fallback al slot anterior válido;
- backoff de reintentos ante fallo.

El CRC se usa solo para integridad, nunca como detector de cambio de estado.
