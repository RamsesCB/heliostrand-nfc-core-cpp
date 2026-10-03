#ifndef NFC_WRITE_POLICY_H
#define NFC_WRITE_POLICY_H

#include <stddef.h>
#include <stdint.h>

inline uint8_t nfcAbsDiff8(uint8_t a, uint8_t b) {
    return a > b ? (uint8_t)(a - b) : (uint8_t)(b - a);
}

inline uint16_t nfcAbsDiff16(uint16_t a, uint16_t b) {
    return a > b ? (uint16_t)(a - b) : (uint16_t)(b - a);
}

inline uint16_t nfcReadBe16(const uint8_t *p) {
    return (uint16_t)(((uint16_t)p[0] << 8) | p[1]);
}

inline bool nfcPayloadMeaningfullyChanged(
    const uint8_t *current,
    const uint8_t *previous,
    uint8_t ldrDelta,
    uint8_t servoDelta,
    uint16_t batteryDeltaMv) {
    if (!current || !previous) return true;

    // Header: version + motor + light direction.
    if (current[0] != previous[0]) return true;

    for (uint8_t i = 2; i <= 5; ++i) {
        if (nfcAbsDiff8(current[i], previous[i]) >= ldrDelta) return true;
    }

    if (nfcAbsDiff8(current[6], previous[6]) >= servoDelta ||
        nfcAbsDiff8(current[7], previous[7]) >= servoDelta) {
        return true;
    }

    const uint16_t batteryNow = nfcReadBe16(current + 8);
    const uint16_t batteryPrevious = nfcReadBe16(previous + 8);
    if ((batteryNow == 0) != (batteryPrevious == 0) ||
        nfcAbsDiff16(batteryNow, batteryPrevious) >= batteryDeltaMv) {
        return true;
    }

    if (current[10] != previous[10]) return true;

    // Byte 1 (sequence) and byte 11 (CRC) are intentionally ignored.
    return false;
}

inline bool nfcShouldWrite(
    bool hasWritten,
    uint32_t elapsedMs,
    bool meaningfulChange,
    uint32_t minimumIntervalMs,
    uint32_t periodicRefreshMs) {
    if (!hasWritten) return true;
    if (elapsedMs < minimumIntervalMs) return false;
    return meaningfulChange || elapsedMs >= periodicRefreshMs;
}

inline bool nfcGenerationNewer(uint8_t candidate, uint8_t reference) {
    const uint8_t diff = (uint8_t)(candidate - reference);
    return diff != 0 && diff < 128;
}

#endif
