# 📡 Especificación Normativa: Protocolo de Telemetría Heliostrand V2

> **Documento Normativo**: Única fuente de la verdad para el empaquetado y decodificación binaria de telemetría.  
> **Ámbito de Aplicación**: Firmware Arduino C++, Estación de Escritorio Java 21 y Aplicación Móvil Flutter.

---

## 1. Características Generales

- **Longitud Invariable**: 12 bytes exactamente ($D_0$ a $D_{11}$).
- **Compatibilidad de Almacenamiento**: Compatible con 3 páginas de memoria de usuario (Páginas 4, 5 y 6) en etiquetas **NTAG213 / ISO 14443-A** (4 bytes por página).
- **Endianness**: Big-Endian (Byte más significativo primero) para valores enteros de 16 bits.
- **Checksum**: CRC-8 sobre los primeros 11 bytes ($D_0$ a $D_{10}$) con polinomio canónico `0x07`.

---

## 2. Estructura de la Trama de 12 Bytes

| Offset | Nombre del Campo | Tipo | Rango Físico / Valores | Descripción / Máscara de Bits |
| :---: | :--- | :---: | :---: | :--- |
| `Byte 0` | `headerFlags` | `uint8_t` | `0x00 - 0xFF` | **Bits 7-6**: Protocol Version (`0b10` = V2)<br>**Bits 5-4**: Estado Motor (`00`=DETENIDO, `01`=ADELANTE, `10`=ATRAS)<br>**Bits 3-0**: Dirección Luz (`0`=EQUILIBRADO, `1`=NORTE, `2`=SUR, `3`=ESTE, `4`=OESTE) |
| `Byte 1` | `sequenceNumber` | `uint8_t` | `0 - 255` | Contador incremental circular de tramas (detección de frescura en lecturas NFC). |
| `Byte 2` | `ldrNorth` | `uint8_t` | `0 - 255` | Intensidad lumínica Norte (ADC 10 bits cuantizado con shift a la derecha `raw >> 2`). |
| `Byte 3` | `ldrSouth` | `uint8_t` | `0 - 255` | Intensidad lumínica Sur (`raw >> 2`). |
| `Byte 4` | `ldrWest` | `uint8_t` | `0 - 255` | Intensidad lumínica Oeste (`raw >> 2`). |
| `Byte 5` | `ldrEast` | `uint8_t` | `0 - 255` | Intensidad lumínica Este (`raw >> 2`). |
| `Byte 6` | `servoPitch` | `uint8_t` | $0 - 180^\circ$ | Ángulo de elevación vertical del seguidor solar. |
| `Byte 7` | `servoYaw` | `uint8_t` | $0 - 180^\circ$ | Ángulo de azimut horizontal del seguidor solar. |
| `Bytes 8-9`| `batteryMilliVolts`| `uint16_t` (BE)| $0 - 6000\text{ mV}$ | Tensión real de batería en milivoltios. Byte 8: MSB, Byte 9: LSB.<br>**Nota**: Un valor de `0` indica sensor desconectado / no disponible. |
| `Byte 10` | `polarityReversals`| `uint8_t` | `0 - 255` | Contador acumulado de inversiones directas de marcha (`ADELANTE \leftrightarrow ATRAS`). |
| `Byte 11` | `crc8` | `uint8_t` | `0x00 - 0xFF` | Verificación de redundancia cíclica calculada sobre Bytes 0 a 10. |

---

## 3. Algoritmo de Verificación CRC-8

El algoritmo de redundancia cíclica opera con:
- **Polinomio Generador**: $P(x) = x^8 + x^2 + x^1 + 1$ (`0x07`)
- **Valor Inicial**: `0x00`
- **Operación**: Desplazamiento a la izquierda con XOR condicional ante el bit 7.

```text
Entrada: Buffer D[0..10]
Salida: Checksum esperado en D[11]

crc = 0x00
para cada byte b en D[0..10]:
    crc ^= b
    para i de 0 a 7:
        si (crc & 0x80) != 0:
            crc = (crc << 1) ^ 0x07
        sino:
            crc = (crc << 1)
        crc &= 0xFF
retornar crc
```

---

## 4. Reglas Semánticas y Validación en Clientes

Cualquier parser (Java, Dart o C++) debe aplicar obligatoriamente dos niveles de validación secuencial:

1. **Nivel 1: Integridad Física de la Trama**:
   - Longitud estricta: `buffer.length == 12` (rechazar tramas menores o mayores).
   - Verificación CRC: Si $\text{CRC-8}(D_0 \dots D_{10}) \neq D_{11}$, rechazar la trama y lanzar `CorruptedPayloadException`.

2. **Nivel 2: Validación Semántica de Límites Físicos**:
   - Versión de protocolo: Bits 7-6 del Byte 0 deben corresponder a versión soportada (`2`).
   - Ángulos de servos: `servoPitch <= 180` y `servoYaw <= 180`.
   - Tensión de batería: Si `batteryMilliVolts > 0`, debe estar dentro del rango admisible ($2500 - 5500\text{ mV}$). Si está fuera de rango, lanzar `InvalidTelemetryException`.
   - Si `batteryMilliVolts == 0`, la UI debe mostrar estado "N/D" (Sensor Desconectado) sin fabricar porcentajes ficticios.
