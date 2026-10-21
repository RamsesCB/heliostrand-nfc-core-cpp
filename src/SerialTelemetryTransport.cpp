#include "SerialTelemetryTransport.h"

SerialTelemetryTransport::SerialTelemetryTransport() {}

bool SerialTelemetryTransport::begin() {
    Serial.begin(SERIAL_BAUD_RATE);
    delay(100);
    return true;
}

bool SerialTelemetryTransport::publish(const uint8_t *payload, size_t length) {
    if (!payload || length != TELEMETRY_PAYLOAD_SIZE) return false;

    Serial.write(0xAA);
    Serial.write(0x55);
    Serial.write(payload, TELEMETRY_PAYLOAD_SIZE);
    Serial.write(0x0D);
    Serial.write(0x0A);
    return true;
}

bool SerialTelemetryTransport::checkCommands(char &outCommand) {
    if (Serial.available() <= 0) return false;
    outCommand = (char)Serial.read();
    return true;
}
