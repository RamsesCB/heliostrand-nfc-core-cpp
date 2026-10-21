#include "NfcTransceiver.h"

#include <string.h>

namespace {
constexpr uint8_t SLOT_A_BASE_PAGE = 4;
constexpr uint8_t SLOT_B_BASE_PAGE = 8;
constexpr uint8_t SLOT_COMMIT_OFFSET = 3;
constexpr uint8_t SLOT_CMD_PAGE = 12;
constexpr uint8_t COMMIT_MAGIC_0 = 0x48; // H
constexpr uint8_t COMMIT_MAGIC_1 = 0x53; // S
constexpr uint8_t CMD_MAGIC_SERVO = 0x53; // S
}

NfcTransceiver::NfcTransceiver()
    : nfc(PIN_PN532_CS),
      pn532Detected(false),
      firmwareVersion(0),
      hasWrittenTelemetry(false),
      lastWriteMillis(0),
      lastAttemptMillis(0),
      lastWrittenPayload{0},
      tagLocked(false),
      lockedUid{0},
      lockedUidLength(0),
      hasPendingServoCommand(false),
      pendingServoPitch(0),
      pendingServoYaw(0) {}

bool NfcTransceiver::begin() {
    nfc.begin();
    firmwareVersion = nfc.getFirmwareVersion();
    if (!firmwareVersion) {
        pn532Detected = false;
        return false;
    }
    nfc.SAMConfig();
    pn532Detected = true;
    return true;
}

bool NfcTransceiver::isMeaningfulChange(const uint8_t *payload) const {
    if (!hasWrittenTelemetry) return true;
    return nfcPayloadMeaningfullyChanged(
        payload,
        lastWrittenPayload,
        NFC_LDR_DELTA_THRESHOLD,
        NFC_SERVO_DELTA_DEG,
        NFC_BATTERY_DELTA_MV);
}

bool NfcTransceiver::validateNtag213() {
    uint8_t cc[4] = {0};
    if (!nfc.ntag2xx_ReadPage(3, cc)) return false;
    return cc[0] == 0xE1 && cc[1] == 0x10 && cc[2] == 0x12;
}

bool NfcTransceiver::uidAllowed(const uint8_t *uid, uint8_t uidLength) {
    if (!uid || uidLength != 7) return false;

#if NFC_ENFORCE_EXPECTED_UID
    return memcmp(uid, NFC_EXPECTED_UID, 7) == 0;
#elif NFC_LOCK_FIRST_TAG_PER_BOOT
    if (!tagLocked) {
        memcpy(lockedUid, uid, uidLength);
        lockedUidLength = uidLength;
        tagLocked = true;
        return true;
    }
    return uidLength == lockedUidLength &&
           memcmp(uid, lockedUid, uidLength) == 0;
#else
    (void)uid;
    (void)uidLength;
    return true;
#endif
}

bool NfcTransceiver::readSlot(
    uint8_t basePage,
    uint8_t *payload,
    uint8_t &generation) {
    if (!payload) return false;

    uint8_t page[4] = {0};
    for (uint8_t i = 0; i < 3; ++i) {
        if (!nfc.ntag2xx_ReadPage((uint8_t)(basePage + i), page)) {
            return false;
        }
        memcpy(payload + i * 4, page, 4);
    }

    uint8_t commit[4] = {0};
    if (!nfc.ntag2xx_ReadPage((uint8_t)(basePage + SLOT_COMMIT_OFFSET), commit)) {
        return false;
    }

    if (commit[0] != COMMIT_MAGIC_0 ||
        commit[1] != COMMIT_MAGIC_1 ||
        commit[3] != (uint8_t)~commit[2]) {
        return false;
    }

    if (!verifyTelemetryCRC(payload, TELEMETRY_PAYLOAD_SIZE)) {
        return false;
    }

    generation = commit[2];
    return true;
}

bool NfcTransceiver::writeSlot(
    uint8_t basePage,
    const uint8_t *payload,
    uint8_t generation) {
    uint8_t page[4] = {0};

    // Payload first; commit page is written last.
    for (uint8_t i = 0; i < 3; ++i) {
        memcpy(page, payload + i * 4, 4);
        if (!nfc.ntag2xx_WritePage((uint8_t)(basePage + i), page)) {
            return false;
        }
    }

    // Verify payload before committing the slot.
    for (uint8_t i = 0; i < 3; ++i) {
        if (!nfc.ntag2xx_ReadPage((uint8_t)(basePage + i), page)) {
            return false;
        }
        if (memcmp(page, payload + i * 4, 4) != 0) {
            return false;
        }
    }

    uint8_t commit[4] = {
        COMMIT_MAGIC_0,
        COMMIT_MAGIC_1,
        generation,
        (uint8_t)~generation
    };
    if (!nfc.ntag2xx_WritePage((uint8_t)(basePage + SLOT_COMMIT_OFFSET), commit)) {
        return false;
    }

    uint8_t verifyCommit[4] = {0};
    return nfc.ntag2xx_ReadPage(
               (uint8_t)(basePage + SLOT_COMMIT_OFFSET),
               verifyCommit) &&
           memcmp(commit, verifyCommit, 4) == 0;
}

bool NfcTransceiver::writeDoubleBuffered(const uint8_t *payload) {
    uint8_t payloadA[TELEMETRY_PAYLOAD_SIZE] = {0};
    uint8_t payloadB[TELEMETRY_PAYLOAD_SIZE] = {0};
    uint8_t genA = 0;
    uint8_t genB = 0;

    const bool validA = readSlot(SLOT_A_BASE_PAGE, payloadA, genA);
    const bool validB = readSlot(SLOT_B_BASE_PAGE, payloadB, genB);

    uint8_t targetBase = SLOT_A_BASE_PAGE;
    uint8_t nextGeneration = 0;

    if (validA && validB) {
        if (nfcGenerationNewer(genA, genB)) {
            targetBase = SLOT_B_BASE_PAGE;
            nextGeneration = (uint8_t)(genA + 1);
        } else {
            targetBase = SLOT_A_BASE_PAGE;
            nextGeneration = (uint8_t)(genB + 1);
        }
    } else if (validA) {
        targetBase = SLOT_B_BASE_PAGE;
        nextGeneration = (uint8_t)(genA + 1);
    } else if (validB) {
        targetBase = SLOT_A_BASE_PAGE;
        nextGeneration = (uint8_t)(genB + 1);
    }

    return writeSlot(targetBase, payload, nextGeneration);
}

bool NfcTransceiver::publish(const uint8_t *payload, size_t length) {
    if (!payload || length != TELEMETRY_PAYLOAD_SIZE || !pn532Detected) {
        return false;
    }

    const unsigned long now = millis();

    if (lastAttemptMillis != 0 &&
        now - lastAttemptMillis < NFC_WRITE_RETRY_BACKOFF_MS) {
        return true;
    }

    const unsigned long elapsed =
        hasWrittenTelemetry ? now - lastWriteMillis : 0;
    const bool meaningfulChange = isMeaningfulChange(payload);
    if (!nfcShouldWrite(
            hasWrittenTelemetry,
            elapsed,
            meaningfulChange,
            NFC_WRITE_MIN_INTERVAL_MS,
            NFC_PERIODIC_REFRESH_MS)) {
        return true;
    }

    uint8_t uid[7] = {0};
    uint8_t uidLength = 0;
    if (!nfc.readPassiveTargetID(
            PN532_MIFARE_ISO14443A,
            uid,
            &uidLength,
            40)) {
        return false;
    }

    if (!validateNtag213() || !uidAllowed(uid, uidLength)) {
        return false;
    }

    lastAttemptMillis = now;
    if (!writeDoubleBuffered(payload)) {
        return false;
    }

    memcpy(lastWrittenPayload, payload, TELEMETRY_PAYLOAD_SIZE);
    hasWrittenTelemetry = true;
    lastWriteMillis = now;

    // Verificar si la aplicación móvil envió una consigna de servomotores en la página de comandos
    uint8_t cmdPitch = 0, cmdYaw = 0;
    if (readServoCommand(cmdPitch, cmdYaw)) {
        pendingServoPitch = cmdPitch;
        pendingServoYaw = cmdYaw;
        hasPendingServoCommand = true;
    }

    return true;
}

bool NfcTransceiver::readServoCommand(uint8_t &pitch, uint8_t &yaw) {
    uint8_t cmd[4] = {0};
    if (!nfc.ntag2xx_ReadPage(SLOT_CMD_PAGE, cmd)) {
        return false;
    }

    // Formato de comando seguro:
    // Byte 0: CMD_MAGIC_SERVO (0x53 = 'S')
    // Byte 1: Pitch (0 a 180 grados)
    // Byte 2: Yaw (0 a 180 grados)
    // Byte 3: Checksum XOR de verificación (0x53 ^ pitch ^ yaw)
    if (cmd[0] == CMD_MAGIC_SERVO &&
        cmd[1] <= 180 &&
        cmd[2] <= 180 &&
        cmd[3] == (uint8_t)(CMD_MAGIC_SERVO ^ cmd[1] ^ cmd[2])) {
        pitch = cmd[1];
        yaw = cmd[2];

        // Limpiar la página de comando para evitar reejecuciones cíclicas (One-shot)
        uint8_t ackPage[4] = {0x00, 0x00, 0x00, 0x00};
        nfc.ntag2xx_WritePage(SLOT_CMD_PAGE, ackPage);
        return true;
    }

    return false;
}

bool NfcTransceiver::fetchServoCommand(uint8_t &pitch, uint8_t &yaw) {
    if (!hasPendingServoCommand) return false;
    pitch = pendingServoPitch;
    yaw = pendingServoYaw;
    hasPendingServoCommand = false;
    return true;
}
