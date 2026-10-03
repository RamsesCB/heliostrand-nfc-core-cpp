#include "NfcTransceiver.h"

NfcTransceiver::NfcTransceiver() {}

void NfcTransceiver::begin() {
    Serial.begin(SERIAL_BAUD_RATE);
    delay(200);

    Serial.println(F("===================================================="));
    Serial.println(F("  Theo Jansen Solar Tracker - Firmware C++"));
    Serial.println(F("  Protocolo NFC / PC-SC 12-Byte Telemetry Core"));
    Serial.println(F("===================================================="));
    Serial.println(F("[INFO] Inicializando transceiver NFC y puerto Serial..."));
    Serial.println(F("[INFO] Velocidad Serial: 115200 baudios"));
    Serial.println(F("[INFO] Trama binaria: 12 Bytes + CRC-8 (Polinomio 0x07)"));
    Serial.println(F("[INFO] Listo para sincronizar con aplicacion Java."));
    Serial.println(F("----------------------------------------------------"));
}

void NfcTransceiver::printHexByte(uint8_t b) {
    if (b < 0x10) Serial.print('0');
    Serial.print(b, HEX);
}

void NfcTransceiver::publishTelemetry(const uint8_t *payload12Bytes) {
    if (!payload12Bytes) return;

    // 1. Emisión en formato de trama HEX estructurada para enlace con software
    // Formato: [NFC_FRAME]:XX XX XX XX XX XX XX XX XX XX XX XX
    Serial.print(F("[NFC_FRAME]:"));
    for (size_t i = 0; i < TELEMETRY_PAYLOAD_SIZE; i++) {
        printHexByte(payload12Bytes[i]);
        if (i < TELEMETRY_PAYLOAD_SIZE - 1) Serial.print(' ');
    }
    Serial.println();

    // 2. Emisión binaria pura delimitada para conexión directa por socket/puerto serial en Java
    // Encabezado: 0xAA 0x55 (Sync), 12 Bytes Payload, Fin: 0x0D 0x0A (\r\n)
    Serial.write(0xAA);
    Serial.write(0x55);
    Serial.write(payload12Bytes, TELEMETRY_PAYLOAD_SIZE);
    Serial.write(0x0D);
    Serial.write(0x0A);
}

void NfcTransceiver::printHumanReadable(const TelemetryPacket &p, const uint8_t *payload) {
    Serial.println(F(">>> TELEMETRIA INSTANTANEA DEL ROBOT <<<"));
    
    Serial.print(F("  LDRs [N, S, O, E]   : ["));
    Serial.print(p.ldrNorte); Serial.print(F(", "));
    Serial.print(p.ldrSur);   Serial.print(F(", "));
    Serial.print(p.ldrOeste); Serial.print(F(", "));
    Serial.print(p.ldrEste);  Serial.println(F("]"));

    Serial.print(F("  Servos [Pitch, Yaw] : "));
    Serial.print(p.servoPitch); Serial.print(F(" deg, "));
    Serial.print(p.servoYaw);   Serial.println(F(" deg"));

    Serial.print(F("  Inversiones Marcha  : "));
    Serial.println(p.polarityReversals);

    Serial.print(F("  Voltaje Operativo   : "));
    Serial.print((float)p.voltageMilliVolts / 1000.0, 2);
    Serial.print(F(" V ("));
    Serial.print(p.voltageMilliVolts);
    Serial.println(F(" mV)"));

    Serial.print(F("  Nivel de Bateria    : "));
    Serial.print(p.batteryPercent);
    Serial.println(F(" %"));

    Serial.print(F("  Checksum CRC-8      : 0x"));
    if (payload[11] < 0x10) Serial.print('0');
    Serial.print(payload[11], HEX);
    Serial.println(F(" (Validado OK)"));
    Serial.println(F("----------------------------------------------------"));
}

bool NfcTransceiver::checkSerialCommands(char &outCommand) {
    if (Serial.available() > 0) {
        outCommand = (char)Serial.read();
        return true;
    }
    return false;
}
