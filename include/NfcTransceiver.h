#ifndef NFC_TRANSCEIVER_H
#define NFC_TRANSCEIVER_H

#include <Arduino.h>
#include "TheoJansenConfig.h"
#include "TheoJansenTelemetry.h"

class NfcTransceiver {
public:
    NfcTransceiver();

    void begin();
    
    // Transmite el búfer de 12 bytes al transpondedor NFC y a través de USB Serial
    void publishTelemetry(const uint8_t *payload12Bytes);

    // Muestra un resumen legible en Serial Monitor
    void printHumanReadable(const TelemetryPacket &packet, const uint8_t *payload12Bytes);

    // Procesa comandos entrantes desde el puerto Serial
    bool checkSerialCommands(char &outCommand);

private:
    void printHexByte(uint8_t b);
};

#endif // NFC_TRANSCEIVER_H
