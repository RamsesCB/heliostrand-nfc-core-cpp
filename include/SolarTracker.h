#ifndef SOLAR_TRACKER_H
#define SOLAR_TRACKER_H

#include <Arduino.h>
#include <Servo.h>
#include "TheoJansenConfig.h"
#include "TheoJansenTelemetry.h"

class SolarTracker {
public:
    SolarTracker();

    void begin();
    void updateSensors();
    void updateTracking();
    void setMotorState(TheoJansenMotorState newState);
    void toggleMotorDirection();

    // Obtener el paquete de telemetría listo para empaquetar
    TelemetryPacket getTelemetrySnapshot();

    uint8_t getPitchAngle() const { return currentPitch; }
    uint8_t getYawAngle() const { return currentYaw; }
    uint8_t getReversalsCount() const { return polarityReversals; }
    TheoJansenMotorState getMotorState() const { return motorState; }
    TheoJansenLightDirection getLightDirection() const { return lightDirection; }

private:
    Servo pitchServo;
    Servo yawServo;

    uint8_t currentPitch;
    uint8_t currentYaw;

    uint8_t ldrNorte;
    uint8_t ldrSur;
    uint8_t ldrOeste;
    uint8_t ldrEste;

    uint16_t voltageMilliVolts;
    uint8_t batteryPercent;
    bool batteryValid;

    uint8_t polarityReversals;
    uint8_t sequenceNumber;
    TheoJansenMotorState motorState;
    TheoJansenLightDirection lightDirection;

    uint8_t readLdr8Bit(uint8_t pin);
    void readPowerSensors();
    void computeLightDirection();
};

#endif // SOLAR_TRACKER_H
