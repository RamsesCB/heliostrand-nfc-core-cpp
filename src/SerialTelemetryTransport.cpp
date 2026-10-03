#include "SerialTelemetryTransport.h"

SerialTelemetryTransport::SerialTelemetryTransport() {}

bool SerialTelemetryTransport::begin() {
    Serial.begin(SERIAL_BAUD_RATE);
    delay(100);
    return true;
}

void SerialTelemetryTransport::printHexByte(uint8_t b) {
    if (b < 0x10) Serial.print('0');
    Serial.print(b, HEX);
}

bool SerialTelemetryTransport::publish(const uint8_t *payload, size_t length) {
    if (!payload || length != TELEMETRY_PAYLOAD_SIZE) return false;

    // Framing Binario Puro Delimitado para Clientes de Software:
    // Sync Magic: 0xAA 0x55 (2 bytes) | Payload (12 bytes) | Fin: 0x0D 0x0A (\r\n)
    Serial.write(0xAA);
    Serial.write(0x55);
    Serial.write(payload, TELEMETRY_PAYLOAD_SIZE);
    Serial.write(0x0D);
    Serial.write(0x0A);
    return true;
}

void SerialTelemetryTransport::printDebugInfo(const TelemetryPacket &p, const uint8_t *payload) {
    // Formato de texto para terminal de depuración
    Serial.print(F("[FRAME_HEX]:"));
    for (size_t i = 0; i < TELEMETRY_PAYLOAD_SIZE; i++) {
        printHexByte(payload[i]);
        if (i < TELEMETRY_PAYLOAD_SIZE - 1) Serial.print(' ');
    }
    Serial.println();

    Serial.print(F("  Seq: ")); Serial.print(p.sequenceNumber);
    Serial.print(F(" | Motor: "));
    if (p.motorState == MOTOR_ADELANTE) Serial.print(F("ADELANTE"));
    else if (p.motorState == MOTOR_ATRAS) Serial.print(F("ATRAS"));
    else Serial.print(F("DETENIDO"));

    Serial.print(F(" | Dir: ")); Serial.print((int)p.lightDirection);
    Serial.print(F(" | Pitch: ")); Serial.print(p.servoPitch);
    Serial.print(F(" | Yaw: ")); Serial.print(p.servoYaw);

    Serial.print(F(" | Bat: "));
    if (p.batteryValid) {
        Serial.print(p.voltageMilliVolts); Serial.print(F("mV"));
    } else {
        Serial.print(F("N/D"));
    }

    Serial.print(F(" | CRC: 0x"));
    printHexByte(payload[11]);
    bool ok = verifyTelemetryCRC(payload, TELEMETRY_PAYLOAD_SIZE);
    Serial.println(ok ? F(" (CRC OK)") : F(" (CRC ERROR)"));
}

bool SerialTelemetryTransport::checkCommands(char &outCommand) {
    if (Serial.available() > 0) {
        outCommand = (char)Serial.read();
        return true;
    }
    return false;
}
