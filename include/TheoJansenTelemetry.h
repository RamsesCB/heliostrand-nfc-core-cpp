#ifndef THEO_JANSEN_TELEMETRY_H
#define THEO_JANSEN_TELEMETRY_H

#include <Arduino.h>
#include "TheoJansenConfig.h"

enum TheoJansenMotorState : uint8_t {
    MOTOR_DETENIDO = 0,
    MOTOR_ADELANTE = 1,
    MOTOR_ATRAS = 2
};

enum TheoJansenLightDirection : uint8_t {
    DIR_EQUILIBRADO = 0,
    DIR_NORTE = 1,
    DIR_SUR = 2,
    DIR_ESTE = 3,
    DIR_OESTE = 4
};

/**
 * Estructura de telemetría del robot Theo Jansen (Protocolo V2).
 */
struct TelemetryPacket {
    uint8_t version;                          // Versión (2 bits: 2)
    TheoJansenMotorState motorState;          // Estado de tracción (2 bits)
    TheoJansenLightDirection lightDirection;  // Dirección solar (4 bits)
    uint8_t sequenceNumber;                   // Byte 1: Secuencia de frescura (0-255)
    uint8_t ldrNorte;                         // Byte 2: 0 a 255
    uint8_t ldrSur;                           // Byte 3: 0 a 255
    uint8_t ldrOeste;                         // Byte 4: 0 a 255
    uint8_t ldrEste;                          // Byte 5: 0 a 255
    uint8_t servoPitch;                       // Byte 6: 0° a 180°
    uint8_t servoYaw;                         // Byte 7: 0° a 180°
    uint16_t voltageMilliVolts;               // Bytes 8-9: mV Big-Endian (0 si sensor desconectado)
    bool batteryValid;                        // Bandera de sensor válido
    uint8_t polarityReversals;                // Byte 10: Inversiones efectivas
    uint8_t checksumCRC8;                     // Byte 11: CRC-8
};

/**
 * Calcula el checksum CRC-8 con polinomio 0x07 (x^8 + x^2 + x + 1).
 */
uint8_t computeCRC8(const uint8_t *data, size_t length);

/**
 * Empaqueta la telemetría en el búfer binario de exactamente 12 bytes.
 */
void packTelemetry(const TelemetryPacket &packet, uint8_t *buffer);

/**
 * Valida la integridad estricta de un búfer de telemetría (debe ser exactamente de 12 bytes).
 */
bool verifyTelemetryCRC(const uint8_t *buffer, size_t length);

#endif // THEO_JANSEN_TELEMETRY_H
