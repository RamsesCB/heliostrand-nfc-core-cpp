#include <Arduino.h>
#include "TheoJansenConfig.h"
#include "TheoJansenTelemetry.h"
#include "SolarTracker.h"
#include "NfcTransceiver.h"

// Instancias de los subsistemas del robot
static SolarTracker tracker;
static NfcTransceiver nfc;

// Variables de temporización no bloqueante
static unsigned long lastTrackingTime = 0;
static unsigned long lastTelemetryTime = 0;
static bool ledState = false;

// Búfer binario continuo de 12 bytes exactamente
static uint8_t telemetryBuffer[TELEMETRY_PAYLOAD_SIZE];

void setup() {
    // Configuración del LED de estado
    pinMode(PIN_STATUS_LED, OUTPUT);
    digitalWrite(PIN_STATUS_LED, HIGH);

    // Inicializar subsistemas
    nfc.begin();
    tracker.begin();

    digitalWrite(PIN_STATUS_LED, LOW);
}

void loop() {
    unsigned long currentMillis = millis();

    // 1. Tarea periódica: Seguimiento solar y ajuste de servomotores / tracción
    if (currentMillis - lastTrackingTime >= TRACKING_INTERVAL_MS) {
        lastTrackingTime = currentMillis;
        tracker.updateTracking();
    }

    // 2. Tarea periódica: Empaquetado y emisión de telemetría NFC / Serial
    if (currentMillis - lastTelemetryTime >= TELEMETRY_INTERVAL_MS) {
        lastTelemetryTime = currentMillis;

        // Capturar instantánea de sensores y estado
        TelemetryPacket snapshot = tracker.getTelemetrySnapshot();

        // Empaquetar en los 12 bytes con CRC-8
        packTelemetry(snapshot, telemetryBuffer);

        // Publicar por NFC y enlace Serial para la aplicación Java
        nfc.publishTelemetry(telemetryBuffer);
        nfc.printHumanReadable(snapshot, telemetryBuffer);

        // Parpadeo de latido (Heartbeat) en el LED
        ledState = !ledState;
        digitalWrite(PIN_STATUS_LED, ledState ? HIGH : LOW);
    }

    // 3. Procesar comandos interactivos desde la consola Serial o Java
    char command;
    if (nfc.checkSerialCommands(command)) {
        switch (command) {
            case 'M':
            case 'm':
                tracker.toggleMotorDirection();
                Serial.println(F("[COMANDO] Direccion del motor Theo Jansen invertida."));
                break;
            case 'T':
            case 't': {
                TelemetryPacket snap = tracker.getTelemetrySnapshot();
                packTelemetry(snap, telemetryBuffer);
                nfc.publishTelemetry(telemetryBuffer);
                break;
            }
            case 'H':
            case 'h':
                tracker.setMotorState(MOTOR_DETENIDO);
                Serial.println(F("[COMANDO] Motor DETENIDO."));
                break;
            case 'F':
            case 'f':
                tracker.setMotorState(MOTOR_ADELANTE);
                Serial.println(F("[COMANDO] Motor ADELANTE."));
                break;
            default:
                break;
        }
    }
}
