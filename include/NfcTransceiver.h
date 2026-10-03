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

    bool isMeaningfulChange(const uint8_t *payload) const;
    bool validateNtag213();
    bool uidAllowed(const uint8_t *uid, uint8_t uidLength);

    bool readSlot(uint8_t basePage, uint8_t *payload, uint8_t &generation);
    bool writeSlot(uint8_t basePage, const uint8_t *payload, uint8_t generation);
    bool writeDoubleBuffered(const uint8_t *payload);

};

#endif
