#include "NfcTransceiver.h"

NfcTransceiver::NfcTransceiver()
    : nfc(PIN_PN532_CS),
      pn532Detected(false),
      firmwareVersion(0),
      lastWriteMillis(0),
      lastWrittenCrc(0) {}

bool NfcTransceiver::begin() {
    Serial.begin(SERIAL_BAUD_RATE);
    delay(100);

    Serial.println(F("[NFC] Inicializando PN532 en bus SPI (CS: D4)..."));
    nfc.begin();

    firmwareVersion = nfc.getFirmwareVersion();
    if (!firmwareVersion) {
        Serial.println(F("[WARN] PN532 no detectado en bus SPI. Operando en modo Serial exclusivo."));
        pn532Detected = false;
        return false;
    }

    Serial.print(F("[INFO] Chip PN532 detectado. Firmware v"));
    Serial.print((firmwareVersion >> 16) & 0xFF, DEC);
    Serial.print('.');
    Serial.println((firmwareVersion >> 8) & 0xFF, DEC);

    // Configurar para lectura/escritura de tarjetas RFID/NFC
    nfc.SAMConfig();
    pn532Detected = true;
    return true;
}

void NfcTransceiver::printHexByte(uint8_t b) {
    if (b < 0x10) Serial.print('0');
    Serial.print(b, HEX);
}

bool NfcTransceiver::publish(const uint8_t *payload, size_t length) {
    if (!payload || length != TELEMETRY_PAYLOAD_SIZE) return false;

    // Emisión Serial delimitada simultánea
    publishTelemetry(payload);

    if (!pn532Detected) {
        return false;
    }

    // Política anti-desgaste EEPROM NTAG213:
    // Solo escribir en páginas si han pasado al menos NFC_WRITE_THROTTLE_MS
    // O si el contenido ha variado (verificado mediante CRC)
    unsigned long now = millis();
    bool contentChanged = (payload[11] != lastWrittenCrc);
    bool timeElapsed = (now - lastWriteMillis >= NFC_WRITE_THROTTLE_MS);

    if (!contentChanged && !timeElapsed) {
        return true; // Throttle activo, no sobreescribir innecesariamente
    }

    // Comprobar presencia de etiqueta NTAG213 con timeout corto (40 ms) para no trabar el ciclo
    uint8_t uid[7];
    uint8_t uidLength = 0;
    bool success = nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A, uid, &uidLength, 40);

    if (success && uidLength > 0) {
        // NTAG213 organiza la memoria de usuario en páginas de 4 bytes:
        // Página 4: Bytes 0..3
        // Página 5: Bytes 4..7
        // Página 6: Bytes 8..11
        uint8_t page4[4] = { payload[0], payload[1], payload[2], payload[3] };
        uint8_t page5[4] = { payload[4], payload[5], payload[6], payload[7] };
        uint8_t page6[4] = { payload[8], payload[9], payload[10], payload[11] };

        bool w4 = nfc.ntag2xx_WritePage(4, page4);
        bool w5 = nfc.ntag2xx_WritePage(5, page5);
        bool w6 = nfc.ntag2xx_WritePage(6, page6);

        if (w4 && w5 && w6) {
            lastWriteMillis = now;
            lastWrittenCrc = payload[11];
            Serial.println(F("[NFC] Telemetria grabada con exito en NTAG213 (Paginas 4-6)."));
            return true;
        } else {
            Serial.println(F("[WARN] Error escribiendo paginas en NTAG213."));
            return false;
        }
    }

    return false;
}

void NfcTransceiver::publishTelemetry(const uint8_t *payload12Bytes) {
    if (!payload12Bytes) return;

    // Emisión binaria pura delimitada para Java / Mobile
    Serial.write(0xAA);
    Serial.write(0x55);
    Serial.write(payload12Bytes, TELEMETRY_PAYLOAD_SIZE);
    Serial.write(0x0D);
    Serial.write(0x0A);
}

void NfcTransceiver::printHumanReadable(const TelemetryPacket &p, const uint8_t *payload) {
    Serial.print(F("[FRAME_HEX]:"));
    for (size_t i = 0; i < TELEMETRY_PAYLOAD_SIZE; i++) {
        printHexByte(payload[i]);
        if (i < TELEMETRY_PAYLOAD_SIZE - 1) Serial.print(' ');
    }
    Serial.println();

    Serial.print(F("  Seq: ")); Serial.print(p.sequenceNumber);
    Serial.print(F(" | Motor: "));
    if (p.motorState == MOTOR_ADELANTE) Serial.print(F("ADELANTE"));
    else if (p.motorState == MOTOR_ATRAS) Serial.print(F("ATRAS"));
    else Serial.print(F("DETENIDO"));

    Serial.print(F(" | Dir: ")); Serial.print((int)p.lightDirection);
    Serial.print(F(" | Pitch: ")); Serial.print(p.servoPitch);
    Serial.print(F(" | Yaw: ")); Serial.print(p.servoYaw);

    Serial.print(F(" | Bat: "));
    if (p.batteryValid) {
        Serial.print(p.voltageMilliVolts); Serial.print(F("mV"));
    } else {
        Serial.print(F("N/D"));
    }

    Serial.print(F(" | CRC: 0x"));
    printHexByte(payload[11]);
    bool valid = verifyTelemetryCRC(payload, TELEMETRY_PAYLOAD_SIZE);
    Serial.println(valid ? F(" (CRC VERIFICADO OK)") : F(" (CRC ERROR)"));
}

bool NfcTransceiver::checkSerialCommands(char &outCommand) {
    if (Serial.available() > 0) {
        outCommand = (char)Serial.read();
        return true;
    }
    return false;
}
