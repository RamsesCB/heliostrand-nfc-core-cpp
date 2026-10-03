#ifndef NFC_TRANSCEIVER_H
#define NFC_TRANSCEIVER_H

#include <Arduino.h>
#include <SPI.h>
#include <Adafruit_PN532.h>
#include "TelemetryTransport.h"
#include "TheoJansenConfig.h"
#include "TheoJansenTelemetry.h"

/**
 * Transceptor NFC para controlador PN532 en bus SPI Hardware.
 * Implementa grabación controlada de páginas 4, 5 y 6 en NTAG213 con política anti-desgaste.
 */
class NfcTransceiver : public TelemetryTransport {
public:
    NfcTransceiver();

    bool begin() override;
    bool publish(const uint8_t *payload, size_t length) override;

    // Métodos de compatibilidad y diagnóstico
    void publishTelemetry(const uint8_t *payload12Bytes);
    void printHumanReadable(const TelemetryPacket &packet, const uint8_t *payload12Bytes);
    bool checkSerialCommands(char &outCommand);

    bool isHardwareDetected() const { return pn532Detected; }
    uint32_t getFirmwareVersion() const { return firmwareVersion; }

private:
    Adafruit_PN532 nfc;
    bool pn532Detected;
    uint32_t firmwareVersion;
    unsigned long lastWriteMillis;
    uint8_t lastWrittenCrc;

    void printHexByte(uint8_t b);
};

#endif // NFC_TRANSCEIVER_H
