#ifndef NFC_TRANSCEIVER_H
#define NFC_TRANSCEIVER_H

#include <Adafruit_PN532.h>
#include <Arduino.h>
#include <SPI.h>

#include "TelemetryTransport.h"
#include "NfcWritePolicy.h"
#include "TheoJansenConfig.h"

class NfcTransceiver : public TelemetryTransport {
public:
    NfcTransceiver();

    bool begin() override;
    bool publish(const uint8_t *payload, size_t length) override;

    bool isHardwareDetected() const { return pn532Detected; }
    uint32_t getFirmwareVersion() const { return firmwareVersion; }

    void pollServoCommand();

    bool fetchServoCommand(uint8_t &pitch, uint8_t &yaw);

private:
    Adafruit_PN532 nfc;
    bool pn532Detected;
    uint32_t firmwareVersion;

    bool hasWrittenTelemetry;
    unsigned long lastWriteMillis;
    unsigned long lastAttemptMillis;
    uint8_t lastWrittenPayload[TELEMETRY_PAYLOAD_SIZE];

    bool tagLocked;
    uint8_t lockedUid[7];
    uint8_t lockedUidLength;

    bool hasPendingServoCommand;
    uint8_t pendingServoPitch;
    uint8_t pendingServoYaw;

    bool isMeaningfulChange(const uint8_t *payload) const;
    bool validateNtag213();
    bool selectTag();
    bool uidAllowed(const uint8_t *uid, uint8_t uidLength);

    bool readSlot(uint8_t basePage, uint8_t *payload, uint8_t &generation);
    bool writeSlot(uint8_t basePage, const uint8_t *payload, uint8_t generation);
    bool writeDoubleBuffered(const uint8_t *payload);
    bool readServoCommand(uint8_t &pitch, uint8_t &yaw);

};

#endif
