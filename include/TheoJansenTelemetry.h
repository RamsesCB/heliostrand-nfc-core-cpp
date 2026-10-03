#ifndef THEO_JANSEN_TELEMETRY_H
#define THEO_JANSEN_TELEMETRY_H

#include <stddef.h>
#include <stdint.h>

#ifndef TELEMETRY_PAYLOAD_SIZE
#define TELEMETRY_PAYLOAD_SIZE 12
#endif

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

struct TelemetryPacket {
    uint8_t version;
    TheoJansenMotorState motorState;
    TheoJansenLightDirection lightDirection;
    uint8_t sequenceNumber;
    uint8_t ldrNorte;
    uint8_t ldrSur;
    uint8_t ldrOeste;
    uint8_t ldrEste;
    uint8_t servoPitch;
    uint8_t servoYaw;
    uint16_t voltageMilliVolts;
    bool batteryValid;
    uint8_t polarityReversals;
    uint8_t checksumCRC8;
};

uint8_t computeCRC8(const uint8_t *data, size_t length);
void packTelemetry(const TelemetryPacket &packet, uint8_t *buffer);
bool verifyTelemetryCRC(const uint8_t *buffer, size_t length);

#endif
