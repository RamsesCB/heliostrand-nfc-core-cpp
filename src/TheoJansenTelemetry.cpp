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

    // Bytes 0 a 3: Sensores LDR (uint8)
    buffer[0] = packet.ldrNorte;
    buffer[1] = packet.ldrSur;
    buffer[2] = packet.ldrOeste;
    buffer[3] = packet.ldrEste;

    // Bytes 4 y 5: Ángulos de servomotores (uint8)
    buffer[4] = packet.servoPitch;
    buffer[5] = packet.servoYaw;

    // Bytes 6 y 7: Inversiones de polaridad (uint16 Big-Endian)
    buffer[6] = (uint8_t)((packet.polarityReversals >> 8) & 0xFF);
    buffer[7] = (uint8_t)(packet.polarityReversals & 0xFF);

    // Bytes 8 y 9: Voltaje de operación en milivoltios (uint16 Big-Endian)
    buffer[8] = (uint8_t)((packet.voltageMilliVolts >> 8) & 0xFF);
    buffer[9] = (uint8_t)(packet.voltageMilliVolts & 0xFF);

    // Byte 10: Porcentaje de batería (uint8)
    buffer[10] = packet.batteryPercent;

    // Byte 11: Checksum CRC-8 calculado sobre los primeros 11 bytes (0..10)
    buffer[11] = computeCRC8(buffer, 11);
}

bool verifyTelemetryCRC(const uint8_t *buffer, size_t length) {
    if (!buffer || length < TELEMETRY_PAYLOAD_SIZE) return false;
    uint8_t expected = computeCRC8(buffer, 11);
    return (buffer[11] == expected);
}
