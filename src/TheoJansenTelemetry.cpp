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

    // Byte 0: Version (Bits 7-6) | MotorState (Bits 5-4) | LightDirection (Bits 3-0)
    uint8_t ver = (packet.version & 0x03) << 6;
    uint8_t mot = ((uint8_t)packet.motorState & 0x03) << 4;
    uint8_t dir = (uint8_t)packet.lightDirection & 0x0F;
    buffer[0] = ver | mot | dir;

    // Byte 1: Número de secuencia (0 a 255)
    buffer[1] = packet.sequenceNumber;

    // Bytes 2 a 5: Sensores LDR (uint8)
    buffer[2] = packet.ldrNorte;
    buffer[3] = packet.ldrSur;
    buffer[4] = packet.ldrOeste;
    buffer[5] = packet.ldrEste;

    // Bytes 6 y 7: Ángulos de servomotores (uint8, 0 a 180 deg)
    buffer[6] = packet.servoPitch;
    buffer[7] = packet.servoYaw;

    // Bytes 8 y 9: Voltaje de batería en milivoltios (uint16 Big-Endian)
    // Si la lectura no es válida, se transmite 0
    uint16_t vToSend = packet.batteryValid ? packet.voltageMilliVolts : 0;
    buffer[8] = (uint8_t)((vToSend >> 8) & 0xFF);
    buffer[9] = (uint8_t)(vToSend & 0xFF);

    // Byte 10: Inversiones de polaridad (uint8)
    buffer[10] = packet.polarityReversals;

    // Byte 11: Checksum CRC-8 calculado sobre los primeros 11 bytes (0..10)
    buffer[11] = computeCRC8(buffer, 11);
}

bool verifyTelemetryCRC(const uint8_t *buffer, size_t length) {
    // Contrato estricto: requiere exactamente TELEMETRY_PAYLOAD_SIZE (12 bytes)
    if (!buffer || length != TELEMETRY_PAYLOAD_SIZE) return false;
    uint8_t expected = computeCRC8(buffer, 11);
    return (buffer[11] == expected);
}
