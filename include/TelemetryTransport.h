#ifndef TELEMETRY_TRANSPORT_H
#define TELEMETRY_TRANSPORT_H

#include <Arduino.h>
#include "TheoJansenTelemetry.h"

/**
 * Interfaz polimórfica para capas de transporte de telemetría.
 */
class TelemetryTransport {
public:
    virtual ~TelemetryTransport() {}
    virtual bool begin() = 0;
    virtual bool publish(const uint8_t *payload, size_t length) = 0;
};

#endif // TELEMETRY_TRANSPORT_H
