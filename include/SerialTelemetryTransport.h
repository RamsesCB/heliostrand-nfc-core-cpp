#ifndef SERIAL_TELEMETRY_TRANSPORT_H
#define SERIAL_TELEMETRY_TRANSPORT_H

#include <Arduino.h>

#include "TelemetryTransport.h"
#include "TheoJansenConfig.h"

class SerialTelemetryTransport : public TelemetryTransport {
public:
    SerialTelemetryTransport();

    bool begin() override;
    bool publish(const uint8_t *payload, size_t length) override;
    bool checkCommands(char &outCommand);
};

#endif
