#ifndef THEO_JANSEN_TELEMETRY_H
#define THEO_JANSEN_TELEMETRY_H

#include <Arduino.h>
#include "TheoJansenConfig.h"

/**
 * Estructura de telemetría del robot Theo Jansen.
 */
struct TelemetryPacket {
    uint8_t ldrNorte;              // Byte 0: 0 a 255
    uint8_t ldrSur;                // Byte 1: 0 a 255
    uint8_t ldrOeste;              // Byte 2: 0 a 255
    uint8_t ldrEste;               // Byte 3: 0 a 255
    uint8_t servoPitch;            // Byte 4: 0° a 180°
    uint8_t servoYaw;              // Byte 5: 0° a 180°
    uint16_t polarityReversals;    // Bytes 6-7: Conteo Big-Endian
    uint16_t voltageMilliVolts;    // Bytes 8-9: mV Big-Endian (ej. 5050 = 5.05V)
    uint8_t batteryPercent;        // Byte 10: 0 a 100%
    uint8_t checksumCRC8;          // Byte 11: CRC-8
};

/**
 * Calcula el checksum CRC-8 con polinomio 0x07 (x^8 + x^2 + x + 1).
 * Idéntico al implementado en el parser de Java de Jenny.
 */
uint8_t computeCRC8(const uint8_t *data, size_t length);

/**
 * Empaqueta la telemetría en el búfer binario de 12 bytes con orden Big-Endian y CRC-8.
 */
void packTelemetry(const TelemetryPacket &packet, uint8_t *buffer);

/**
 * Valida la integridad de un búfer de telemetría de 12 bytes.
 */
bool verifyTelemetryCRC(const uint8_t *buffer, size_t length);

#endif // THEO_JANSEN_TELEMETRY_H
