#include "TheoJansenTelemetry.h"

uint8_t computeCRC8(const uint8_t *data, size_t length) {
    uint8_t crc = 0x00;
    for (size_t i = 0; i < length; i++) {
        crc ^= data[i];
        for (uint8_t j = 0; j < 8; j++) {
            if (crc & 0x80) {
                crc = (crc << 1) ^ 0x07;
            } else {
                crc = (crc << 1);
            }
        }
    }
    return crc;
}

void packTelemetry(const TelemetryPacket &packet, uint8_t *buffer) {
    if (!buffer) return;

    uint8_t ver = (packet.version & 0x03) << 6;
    uint8_t mot = ((uint8_t)packet.motorState & 0x03) << 4;
    uint8_t dir = (uint8_t)packet.lightDirection & 0x0F;
    buffer[0] = ver | mot | dir;

    buffer[1] = packet.sequenceNumber;

    buffer[2] = packet.ldrNorte;
    buffer[3] = packet.ldrSur;
    buffer[4] = packet.ldrOeste;
    buffer[5] = packet.ldrEste;

    buffer[6] = packet.servoPitch;
    buffer[7] = packet.servoYaw;

    uint16_t vToSend = packet.batteryValid ? packet.voltageMilliVolts : 0;
    buffer[8] = (uint8_t)((vToSend >> 8) & 0xFF);
    buffer[9] = (uint8_t)(vToSend & 0xFF);

    buffer[10] = packet.polarityReversals;

    buffer[11] = computeCRC8(buffer, 11);
}

bool verifyTelemetryCRC(const uint8_t *buffer, size_t length) {

    if (!buffer || length != TELEMETRY_PAYLOAD_SIZE) return false;
    uint8_t expected = computeCRC8(buffer, 11);
    return (buffer[11] == expected);
}
