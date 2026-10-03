#include <Arduino.h>

#include "NfcTransceiver.h"
#include "SerialTelemetryTransport.h"
#include "SolarTracker.h"
#include "TheoJansenConfig.h"
#include "TheoJansenTelemetry.h"

static SolarTracker tracker;
static NfcTransceiver nfcTransport;
static SerialTelemetryTransport serialTransport;

static unsigned long lastTrackingTime = 0;
static unsigned long lastTelemetryTime = 0;
static bool ledState = false;
static uint8_t telemetryBuffer[TELEMETRY_PAYLOAD_SIZE];

void setup() {
    pinMode(PIN_STATUS_LED, OUTPUT);
    digitalWrite(PIN_STATUS_LED, HIGH);

    serialTransport.begin();
    nfcTransport.begin();
    tracker.begin();

    digitalWrite(PIN_STATUS_LED, LOW);
}

void loop() {
    const unsigned long currentMillis = millis();

    if (currentMillis - lastTrackingTime >= TRACKING_INTERVAL_MS) {
        lastTrackingTime = currentMillis;
        tracker.updateTracking();
    }

    if (currentMillis - lastTelemetryTime >= TELEMETRY_INTERVAL_MS) {
        lastTelemetryTime = currentMillis;

        const TelemetryPacket snapshot = tracker.getTelemetrySnapshot();
        packTelemetry(snapshot, telemetryBuffer);

        // Binary UART and NFC are independent transports.
        serialTransport.publish(telemetryBuffer, TELEMETRY_PAYLOAD_SIZE);
        nfcTransport.publish(telemetryBuffer, TELEMETRY_PAYLOAD_SIZE);

        ledState = !ledState;
        digitalWrite(PIN_STATUS_LED, ledState ? HIGH : LOW);
    }

    char command;
    if (serialTransport.checkCommands(command)) {
        switch (command) {
            case 'M':
            case 'm':
                tracker.toggleMotorDirection();
                break;
            case 'T':
            case 't': {
                const TelemetryPacket snap = tracker.getTelemetrySnapshot();
                packTelemetry(snap, telemetryBuffer);
                serialTransport.publish(telemetryBuffer, TELEMETRY_PAYLOAD_SIZE);
                break;
            }
            case 'H':
            case 'h':
                tracker.setMotorState(MOTOR_DETENIDO);
                break;
            case 'F':
            case 'f':
                tracker.setMotorState(MOTOR_ADELANTE);
                break;
            default:
                break;
        }
    }
}
